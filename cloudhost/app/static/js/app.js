/**
 * CloudHost: Client-Side Logic
 * - Real-time asynchronous service health checking
 * - Drag-and-drop validation & constraints enforcement
 * - Strictly no emojis, minimalist feedback
 */

document.addEventListener("DOMContentLoaded", function () {
    // -------------------------------------------------------------------------
    // 1. Asynchronous Health Checking
    // -------------------------------------------------------------------------
    const navHealthStatus = document.getElementById("nav-health-status");
    const navHealthText = document.getElementById("nav-health-text");
    const dbDot = document.getElementById("db-health-dot");
    const dbLabel = document.getElementById("db-health-label");
    const s3Dot = document.getElementById("s3-health-dot");
    const s3Label = document.getElementById("s3-health-label");
    const lambdaDot = document.getElementById("lambda-health-dot");
    const lambdaLabel = document.getElementById("lambda-health-label");

    async function evaluateInfrastructureHealth() {
        let dbActive = false;
        let s3Active = false;
        let lambdaActive = false;

        // DynamoDB Check
        try {
            const dbResp = await fetch("/health/db");
            const dbData = await dbResp.json();
            if (dbResp.ok && dbData.status === "healthy") {
                dbActive = true;
                if (dbDot) dbDot.className = "status-indicator-dot bg-success";
                if (dbLabel) dbLabel.textContent = "DynamoDB (Active)";
            } else {
                if (dbDot) dbDot.className = "status-indicator-dot bg-danger";
                if (dbLabel) dbLabel.textContent = "DynamoDB (Degraded)";
            }
        } catch (e) {
            if (dbDot) dbDot.className = "status-indicator-dot bg-danger";
            if (dbLabel) dbLabel.textContent = "DynamoDB (Error)";
        }

        // S3 Check
        try {
            const s3Resp = await fetch("/health/s3");
            const s3Data = await s3Resp.json();
            if (s3Resp.ok && s3Data.status === "healthy") {
                s3Active = true;
                if (s3Dot) s3Dot.className = "status-indicator-dot bg-success";
                if (s3Label) s3Label.textContent = "Amazon S3 (Encrypted)";
            } else {
                if (s3Dot) s3Dot.className = "status-indicator-dot bg-danger";
                if (s3Label) s3Label.textContent = "Amazon S3 (Degraded)";
            }
        } catch (e) {
            if (s3Dot) s3Dot.className = "status-indicator-dot bg-danger";
            if (s3Label) s3Label.textContent = "Amazon S3 (Error)";
        }

        // Lambda Check
        try {
            const lResp = await fetch("/health/lambda");
            const lData = await lResp.json();
            if (lResp.ok && lData.status === "healthy") {
                lambdaActive = true;
                if (lambdaDot) lambdaDot.className = "status-indicator-dot bg-success";
                if (lambdaLabel) lambdaLabel.textContent = "AWS Lambda (Ready)";
            } else {
                if (lambdaDot) lambdaDot.className = "status-indicator-dot bg-secondary";
                if (lambdaLabel) lambdaLabel.textContent = "AWS Lambda (Standby)";
            }
        } catch (e) {
            if (lambdaDot) lambdaDot.className = "status-indicator-dot bg-secondary";
            if (lambdaLabel) lambdaLabel.textContent = "AWS Lambda (Standby)";
        }

        // Update Navbar Status Pill
        if (navHealthStatus && navHealthText) {
            navHealthStatus.classList.remove("status-evaluating", "status-healthy", "status-degraded");
            if (dbActive && s3Active) {
                navHealthStatus.classList.add("status-healthy");
                navHealthText.textContent = "All Cloud Services Operational";
            } else if (dbActive || s3Active) {
                navHealthStatus.classList.add("status-degraded");
                navHealthText.textContent = "Partial Service Degradation";
            } else {
                navHealthStatus.classList.add("status-degraded");
                navHealthText.textContent = "Services Offline";
            }
        }
    }

    evaluateInfrastructureHealth();

    // -------------------------------------------------------------------------
    // 2. Drag & Drop and Upload Validation
    // -------------------------------------------------------------------------
    const dropZone = document.getElementById("drop-zone");
    const fileInput = document.getElementById("file-input");
    const fileDetails = document.getElementById("file-details");
    const selectedFileName = document.getElementById("selected-file-name");
    const selectedFileSize = document.getElementById("selected-file-size");
    const validationError = document.getElementById("client-validation-error");

    const MAX_SIZE_BYTES = 10 * 1024 * 1024; // 10MB
    const ALLOWED_EXTS = [
        "txt", "pdf", "png", "jpg", "jpeg", "gif", "csv",
        "docx", "xlsx", "zip", "json", "md", "html", "yaml", "yml"
    ];

    function validateAndShowFile(file) {
        if (!file) return;

        if (validationError) {
            validationError.textContent = "";
            validationError.classList.add("d-none");
        }

        const ext = file.name.split(".").pop().toLowerCase();
        
        if (!ALLOWED_EXTS.includes(ext)) {
            if (validationError) {
                validationError.textContent = `Extension '.${ext}' is not permitted by policy.`;
                validationError.classList.remove("d-none");
            }
            if (fileInput) fileInput.value = "";
            if (fileDetails) fileDetails.classList.add("d-none");
            return false;
        }

        if (file.size > MAX_SIZE_BYTES) {
            if (validationError) {
                validationError.textContent = `File size exceeds the 10 MB limit.`;
                validationError.classList.remove("d-none");
            }
            if (fileInput) fileInput.value = "";
            if (fileDetails) fileDetails.classList.add("d-none");
            return false;
        }

        if (selectedFileName && selectedFileSize && fileDetails) {
            selectedFileName.textContent = file.name;
            const sizeStr = file.size < 1024 * 1024 
                ? (file.size / 1024).toFixed(1) + " KB" 
                : (file.size / (1024 * 1024)).toFixed(2) + " MB";
            selectedFileSize.textContent = sizeStr;
            fileDetails.classList.remove("d-none");
        }
        return true;
    }

    if (fileInput) {
        fileInput.addEventListener("change", function () {
            if (fileInput.files.length > 0) {
                validateAndShowFile(fileInput.files[0]);
            }
        });
    }

    if (dropZone) {
        ["dragenter", "dragover"].forEach(eventName => {
            dropZone.addEventListener(eventName, function (e) {
                e.preventDefault();
                e.stopPropagation();
                dropZone.classList.add("dragover");
            }, false);
        });

        ["dragleave", "drop"].forEach(eventName => {
            dropZone.addEventListener(eventName, function (e) {
                e.preventDefault();
                e.stopPropagation();
                dropZone.classList.remove("dragover");
            }, false);
        });

        dropZone.addEventListener("drop", function (e) {
            const dt = e.dataTransfer;
            const files = dt.files;
            if (files.length > 0 && fileInput) {
                fileInput.files = files;
                validateAndShowFile(files[0]);
            }
        }, false);
    }
});
