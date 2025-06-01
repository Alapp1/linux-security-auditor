from flask import Blueprint, render_template, jsonify, request, redirect, url_for
import json
import os
from datetime import datetime
import threading
from .models import ScanHistory, SecurityScanner

main = Blueprint("main", __name__)

# Global scan status
scan_status = {"running": False, "last_scan": None}


@main.route("/")
def dashboard():
    if os.path.exists("security_report.json"):
        with open("security_report.json", "r") as f:
            current_report = json.load(f)
    else:
        current_report = {"findings": [], "total_findings": 0}

    scan_history = ScanHistory.load_history()

    return render_template(
        "dashboard.html",
        report=current_report,
        scan_status=scan_status,
        scan_history=scan_history,
    )


@main.route("/scan/<scan_id>")
def view_scan(scan_id):
    """View a specific scan from history"""
    scan = ScanHistory.get_scan_by_id(scan_id)

    if not scan:
        return redirect(url_for("main.dashboard"))

    scan_history = ScanHistory.load_history()
    return render_template(
        "dashboard.html",
        report=scan,
        scan_status=scan_status,
        scan_history=scan_history,
        viewing_historical=True,
    )


@main.route("/scan", methods=["POST"])
def trigger_scan():
    if scan_status["running"]:
        return jsonify({"error": "Scan already running"}), 400

    # Get form data
    host = request.form.get("host", "localhost")
    port = request.form.get("port", "2222")
    username = request.form.get("username", "root")
    password = request.form.get("password", "password")
    target_name = request.form.get("target_name", "Custom Target")

    # Validate inputs
    try:
        port = int(port)
    except ValueError:
        return jsonify({"error": "Invalid port number"}), 400

    # Run scan in background thread
    def run_scan():
        scan_status["running"] = True
        try:
            SecurityScanner.run_scan(host, port, username, password, target_name)
            scan_status["last_scan"] = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        finally:
            scan_status["running"] = False

    thread = threading.Thread(target=run_scan)
    thread.start()

    return redirect(url_for("main.dashboard"))


@main.route("/status")
def get_status():
    return jsonify(scan_status)
