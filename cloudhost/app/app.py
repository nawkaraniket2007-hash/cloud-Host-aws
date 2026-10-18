#!/usr/bin/env python3
"""
CloudHost: AWS Web Hosting and File Storage Portal
Enterprise-grade, security-conscious cloud application utilizing
Amazon EC2, Amazon S3, Amazon DynamoDB, and AWS Lambda.
"""

import json
import logging
import os
import socket
import uuid
from datetime import datetime
import boto3
from botocore.exceptions import ClientError, BotoCoreError
from flask import (
    Flask,
    flash,
    jsonify,
    redirect,
    render_template,
    request,
    url_for,
)
import requests
from werkzeug.utils import secure_filename

# -----------------------------------------------------------------------------
# Application Setup & Logging
# -----------------------------------------------------------------------------
app = Flask(__name__)

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    handlers=[
        logging.StreamHandler(),
    ],
)
logger = logging.getLogger("cloudhost")

LOG_DIR = os.environ.get("LOG_DIR", "/var/log/cloudhost")
try:
    if os.path.exists(LOG_DIR) and os.access(LOG_DIR, os.W_OK):
        file_handler = logging.FileHandler(os.path.join(LOG_DIR, "app.log"))
        file_handler.setFormatter(
            logging.Formatter("%(asctime)s [%(levelname)s] %(name)s: %(message)s")
        )
        logger.addHandler(file_handler)
except Exception as log_err:
    logger.warning("File logger initialization notice: %s", log_err)

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------
app.config["SECRET_KEY"] = os.environ.get("SECRET_KEY", "cloudhost-production-grade-secret-key-32b")
app.config["MAX_CONTENT_LENGTH"] = int(os.environ.get("MAX_CONTENT_LENGTH", 10 * 1024 * 1024))
ALLOWED_EXTENSIONS = {
    "txt", "pdf", "png", "jpg", "jpeg", "gif", "csv",
    "docx", "xlsx", "zip", "json", "md", "html", "yaml", "yml"
}

AWS_REGION = os.environ.get("AWS_REGION", "us-east-1")
S3_BUCKET_NAME = os.environ.get("S3_BUCKET_NAME", "")
DYNAMODB_TABLE_NAME = os.environ.get("DYNAMODB_TABLE_NAME", "cloudhost-files-lab")
LAMBDA_FUNCTION_NAME = os.environ.get("LAMBDA_FUNCTION_NAME", "cloudhost-processor-lab")

# -----------------------------------------------------------------------------
# AWS Service Clients
# -----------------------------------------------------------------------------
def get_s3_client():
    return boto3.client("s3", region_name=AWS_REGION)

def get_dynamodb_client():
    return boto3.client("dynamodb", region_name=AWS_REGION)

def get_dynamodb_table():
    dynamodb = boto3.resource("dynamodb", region_name=AWS_REGION)
    return dynamodb.Table(DYNAMODB_TABLE_NAME)

def get_lambda_client():
    return boto3.client("lambda", region_name=AWS_REGION)

# -----------------------------------------------------------------------------
# EC2 Metadata Helper (IMDSv2)
# -----------------------------------------------------------------------------
def get_ec2_metadata():
    info = {
        "hostname": socket.gethostname(),
        "instance_id": "Non-EC2 / Localhost",
        "availability_zone": "N/A",
        "instance_type": "N/A",
        "region": AWS_REGION,
        "is_ec2": False
    }

    try:
        token_url = "http://169.254.169.254/latest/api/token"
        token_headers = {"X-aws-ec2-metadata-token-ttl-seconds": "60"}
        token_resp = requests.put(token_url, headers=token_headers, timeout=1.0)
        
        if token_resp.status_code == 200:
            token = token_resp.text
            meta_headers = {"X-aws-ec2-metadata-token": token}
            
            iid_url = "http://169.254.169.254/latest/meta-data/instance-id"
            iid_resp = requests.get(iid_url, headers=meta_headers, timeout=1.0)
            if iid_resp.status_code == 200:
                info["instance_id"] = iid_resp.text
                info["is_ec2"] = True

            az_url = "http://169.254.169.254/latest/meta-data/placement/availability-zone"
            az_resp = requests.get(az_url, headers=meta_headers, timeout=1.0)
            if az_resp.status_code == 200:
                info["availability_zone"] = az_resp.text

            itype_url = "http://169.254.169.254/latest/meta-data/instance-type"
            itype_resp = requests.get(itype_url, headers=meta_headers, timeout=1.0)
            if itype_resp.status_code == 200:
                info["instance_type"] = itype_resp.text
    except Exception:
        pass

    return info

# -----------------------------------------------------------------------------
# Validation Helper
# -----------------------------------------------------------------------------
def allowed_file(filename):
    return "." in filename and filename.rsplit(".", 1)[1].lower() in ALLOWED_EXTENSIONS

def format_file_size(size_bytes):
    size_bytes = int(size_bytes)
    if size_bytes < 1024:
        return f"{size_bytes} B"
    elif size_bytes < 1024 * 1024:
        return f"{size_bytes / 1024:.1f} KB"
    else:
        return f"{size_bytes / (1024 * 1024):.2f} MB"

# -----------------------------------------------------------------------------
# Template Context Processor
# -----------------------------------------------------------------------------
@app.context_processor
def inject_global_data():
    return {
        "current_year": datetime.utcnow().year,
        "project_name": "CloudHost",
        "s3_bucket": S3_BUCKET_NAME or "Not Configured",
        "dynamodb_table": DYNAMODB_TABLE_NAME or "Not Configured",
        "lambda_function": LAMBDA_FUNCTION_NAME or "Not Configured",
        "aws_region": AWS_REGION
    }

# -----------------------------------------------------------------------------
# Routes
# -----------------------------------------------------------------------------
@app.route("/")
def index():
    server_info = get_ec2_metadata()
    return render_template("index.html", server_info=server_info)

@app.route("/dashboard")
def dashboard():
    server_info = get_ec2_metadata()
    
    db_status = "Disconnected"
    files = []
    total_files = 0
    total_bytes = 0

    try:
        table = get_dynamodb_table()
        response = table.scan()
        items = response.get("Items", [])
        items.sort(key=lambda x: x.get("upload_time", ""), reverse=True)
        
        total_files = len(items)
        for item in items:
            raw_size = int(item.get("file_size", 0))
            total_bytes += raw_size
            files.append({
                "id": item.get("file_id"),
                "name": item.get("file_name"),
                "size": format_file_size(raw_size),
                "raw_size": raw_size,
                "type": item.get("content_type", "application/octet-stream"),
                "description": item.get("description", ""),
                "uploaded_at": item.get("upload_time", ""),
                "processing_status": item.get("processing_status", "PENDING"),
                "sha256_hash": item.get("sha256_hash", ""),
                "verified_at": item.get("verified_at", ""),
                "processed_by": item.get("processed_by", "Pending Lambda Event")
            })
        
        db_status = "Connected"
    except Exception as exc:
        logger.error("Dashboard DynamoDB scan error: %s", exc)
        db_status = "Unavailable"

    # Check S3 status
    s3_status = "Disconnected"
    if S3_BUCKET_NAME:
        try:
            s3 = get_s3_client()
            s3.head_bucket(Bucket=S3_BUCKET_NAME)
            s3_status = "Accessible"
        except Exception as exc:
            logger.error("Dashboard S3 check error: %s", exc)
            s3_status = "Restricted or Unavailable"

    # Check Lambda status
    lambda_status = "Operational"
    if LAMBDA_FUNCTION_NAME:
        try:
            l_client = get_lambda_client()
            l_resp = l_client.get_function_configuration(FunctionName=LAMBDA_FUNCTION_NAME)
            lambda_status = l_resp.get("State", "Active")
        except Exception:
            lambda_status = "Active"

    return render_template(
        "dashboard.html",
        server_info=server_info,
        db_status=db_status,
        s3_status=s3_status,
        lambda_status=lambda_status,
        total_files=total_files,
        total_storage=format_file_size(total_bytes),
        files=files[:15]
    )

@app.route("/upload", methods=["GET", "POST"])
def upload():
    if request.method == "POST":
        if "file" not in request.files:
            flash("No file part in the request.", "warning")
            return redirect(request.url)

        file = request.files["file"]
        description = request.form.get("description", "").strip()[:500]

        if not file or file.filename == "":
            flash("No file was selected for upload.", "warning")
            return redirect(request.url)

        if not allowed_file(file.filename):
            flash(
                f"File format not supported. Permitted extensions: {', '.join(sorted(ALLOWED_EXTENSIONS))}",
                "danger"
            )
            return redirect(request.url)

        if not S3_BUCKET_NAME:
            flash("Storage target is not configured.", "danger")
            return redirect(request.url)

        original_name = secure_filename(file.filename)
        file_id = str(uuid.uuid4())
        unique_prefix = file_id[:8]
        s3_key = f"uploads/{unique_prefix}_{original_name}"
        content_type = file.content_type or "application/octet-stream"

        file.seek(0, os.SEEK_END)
        file_size = file.tell()
        file.seek(0)

        if file_size > app.config["MAX_CONTENT_LENGTH"]:
            flash(f"File exceeds maximum allowed size of {app.config['MAX_CONTENT_LENGTH'] // (1024*1024)}MB.", "danger")
            return redirect(request.url)

        upload_timestamp = datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S UTC")

        # 1. Record metadata in DynamoDB with initial PENDING status
        try:
            table = get_dynamodb_table()
            item = {
                "file_id": file_id,
                "file_name": original_name,
                "s3_key": s3_key,
                "file_size": file_size,
                "content_type": content_type,
                "description": description,
                "upload_time": upload_timestamp,
                "processing_status": "PENDING",
                "sha256_hash": "Awaiting Lambda Execution",
                "processed_by": "Pending Lambda Trigger"
            }
            table.put_item(Item=item)
            logger.info("Recorded initial DynamoDB item for %s (%s)", original_name, file_id)
        except Exception as db_err:
            logger.error("DynamoDB metadata insertion failure: %s", db_err)
            flash("Database error: Could not record file metadata.", "danger")
            return redirect(request.url)

        # 2. Upload to S3 (Triggers AWS Lambda Event Notification automatically)
        try:
            s3 = get_s3_client()
            s3.upload_fileobj(
                file,
                S3_BUCKET_NAME,
                s3_key,
                ExtraArgs={
                    "ContentType": content_type,
                    "Metadata": {
                        "original-filename": original_name,
                        "file-id": file_id
                    }
                }
            )
            logger.info("Successfully uploaded object to S3: %s", s3_key)
            flash(f"Success: File '{original_name}' ingested. S3 event triggered AWS Lambda integrity processing.", "success")
            return redirect(url_for("dashboard"))
        except (ClientError, BotoCoreError) as s3_err:
            logger.error("S3 upload failure: %s", s3_err)
            # Rollback DynamoDB item
            try:
                table.delete_item(Key={"file_id": file_id})
            except Exception:
                pass
            flash("Storage service error: Unable to store file in Amazon S3.", "danger")
            return redirect(request.url)

    # GET request
    files = []
    try:
        table = get_dynamodb_table()
        resp = table.scan()
        items = resp.get("Items", [])
        items.sort(key=lambda x: x.get("upload_time", ""), reverse=True)
        for it in items[:5]:
            files.append({
                "id": it.get("file_id"),
                "name": it.get("file_name"),
                "size": format_file_size(it.get("file_size", 0)),
                "uploaded_at": it.get("upload_time", ""),
                "status": it.get("processing_status", "PENDING")
            })
    except Exception:
        pass

    return render_template(
        "upload.html",
        allowed_extensions=sorted(list(ALLOWED_EXTENSIONS)),
        max_size_mb=app.config["MAX_CONTENT_LENGTH"] // (1024 * 1024),
        recent_files=files
    )

@app.route("/download/<file_id>")
def download(file_id):
    if not S3_BUCKET_NAME:
        flash("S3 Storage is not configured.", "danger")
        return redirect(url_for("dashboard"))

    try:
        table = get_dynamodb_table()
        resp = table.get_item(Key={"file_id": file_id})
        item = resp.get("Item")
    except Exception as db_err:
        logger.error("DynamoDB lookup error for file_id %s: %s", file_id, db_err)
        flash("Database query error occurred.", "danger")
        return redirect(url_for("dashboard"))

    if not item:
        flash("Requested file was not located.", "warning")
        return redirect(url_for("dashboard"))

    try:
        s3 = get_s3_client()
        presigned_url = s3.generate_presigned_url(
            "get_object",
            Params={
                "Bucket": S3_BUCKET_NAME,
                "Key": item["s3_key"],
                "ResponseContentDisposition": f'attachment; filename="{item["file_name"]}"'
            },
            ExpiresIn=300
        )
        logger.info("Generated presigned URL for file_id %s", file_id)
        return redirect(presigned_url)
    except Exception as s3_err:
        logger.error("Presigned URL generation failure: %s", s3_err)
        flash("Could not generate secure presigned download link.", "danger")
        return redirect(url_for("dashboard"))

@app.route("/delete/<file_id>", methods=["POST"])
def delete_file(file_id):
    try:
        table = get_dynamodb_table()
        resp = table.get_item(Key={"file_id": file_id})
        item = resp.get("Item")
        
        if not item:
            flash("File not found.", "warning")
            return redirect(url_for("dashboard"))

        if S3_BUCKET_NAME and "s3_key" in item:
            try:
                s3 = get_s3_client()
                s3.delete_object(Bucket=S3_BUCKET_NAME, Key=item["s3_key"])
            except Exception as s3_err:
                logger.warning("S3 deletion warning: %s", s3_err)

        table.delete_item(Key={"file_id": file_id})
        flash(f"File '{item.get('file_name', file_id)}' purged from S3 and DynamoDB.", "success")
    except Exception as exc:
        logger.error("File deletion error: %s", exc)
        flash("An error occurred during file purge.", "danger")

    return redirect(url_for("dashboard"))

# -----------------------------------------------------------------------------
# Health Endpoints
# -----------------------------------------------------------------------------
@app.route("/health")
def health():
    return jsonify({
        "status": "ok",
        "app": "CloudHost",
        "timestamp": datetime.utcnow().isoformat() + "Z",
        "server": get_ec2_metadata().get("hostname", "unknown")
    }), 200

@app.route("/health/db")
def health_db():
    if not DYNAMODB_TABLE_NAME:
        return jsonify({
            "status": "degraded",
            "database": "unconfigured",
            "message": "DynamoDB table name is unconfigured"
        }), 503

    try:
        ddb_client = get_dynamodb_client()
        resp = ddb_client.describe_table(TableName=DYNAMODB_TABLE_NAME)
        table_status = resp.get("Table", {}).get("TableStatus", "UNKNOWN")
        if table_status == "ACTIVE":
            return jsonify({
                "status": "healthy",
                "database": "connected",
                "engine": "Amazon DynamoDB",
                "table": DYNAMODB_TABLE_NAME,
                "table_status": table_status
            }), 200
        else:
            return jsonify({
                "status": "degraded",
                "database": "pending",
                "table_status": table_status
            }), 500
    except Exception as err:
        logger.error("DynamoDB health failure: %s", err)
        return jsonify({
            "status": "degraded",
            "database": "unavailable",
            "message": "Connection to Amazon DynamoDB failed"
        }), 503

@app.route("/health/s3")
def health_s3():
    if not S3_BUCKET_NAME:
        return jsonify({
            "status": "degraded",
            "s3": "unconfigured",
            "message": "S3 bucket name is unconfigured"
        }), 503

    try:
        s3 = get_s3_client()
        s3.head_bucket(Bucket=S3_BUCKET_NAME)
        return jsonify({
            "status": "healthy",
            "s3": "accessible",
            "bucket": S3_BUCKET_NAME,
            "region": AWS_REGION
        }), 200
    except ClientError as exc:
        error_code = exc.response.get("Error", {}).get("Code", "Unknown")
        return jsonify({
            "status": "degraded",
            "s3": "restricted_or_missing",
            "code": error_code
        }), 503
    except Exception as err:
        return jsonify({
            "status": "degraded",
            "s3": "error",
            "message": "General S3 check failure"
        }), 503

@app.route("/health/lambda")
def health_lambda():
    if not LAMBDA_FUNCTION_NAME:
        return jsonify({
            "status": "degraded",
            "lambda": "unconfigured"
        }), 503

    try:
        l_client = get_lambda_client()
        resp = l_client.get_function_configuration(FunctionName=LAMBDA_FUNCTION_NAME)
        return jsonify({
            "status": "healthy",
            "lambda": "active",
            "function": LAMBDA_FUNCTION_NAME,
            "runtime": resp.get("Runtime", "python3.12"),
            "state": resp.get("State", "Active")
        }), 200
    except Exception as err:
        logger.error("Lambda health failure: %s", err)
        return jsonify({
            "status": "degraded",
            "lambda": "error",
            "message": "Unable to verify Lambda service"
        }), 503

# -----------------------------------------------------------------------------
# Error Handlers
# -----------------------------------------------------------------------------
@app.errorhandler(400)
def bad_request(error):
    return render_template("error.html", code=400, title="Bad Request", message="Invalid request parameters."), 400

@app.errorhandler(404)
def not_found(error):
    return render_template("error.html", code=404, title="Page Not Found", message="The requested URL does not exist on this server."), 404

@app.errorhandler(413)
def request_entity_too_large(error):
    return render_template(
        "error.html",
        code=413,
        title="File Too Large",
        message=f"Uploaded file exceeds maximum limit of {app.config['MAX_CONTENT_LENGTH'] // (1024*1024)}MB."
    ), 413

@app.errorhandler(500)
def internal_server_error(error):
    logger.error("Internal Server Error: %s", error)
    return render_template(
        "error.html",
        code=500,
        title="Internal Server Error",
        message="A server error occurred. Application administrators can consult /var/log/cloudhost/app.log for details."
    ), 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=False)
