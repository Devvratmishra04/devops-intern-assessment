"""
Sample Django views used for CI/CD SAST rule validation and testing.
Contains both secure and vulnerable patterns to evaluate SAST framework-specific detection.
"""

from django.http import JsonResponse, HttpResponse
from django.db import connection
from django.views.decorators.csrf import csrf_exempt
import json

def user_profile_safe(request):
    """
    SECURE PATTERN: Parameterized query in Django raw SQL.
    """
    user_id = request.GET.get('id', '1')
    with connection.cursor() as cursor:
        cursor.execute("SELECT id, username, email FROM auth_user WHERE id = %s", [user_id])
        row = cursor.fetchone()
    
    if row:
        return JsonResponse({"id": row[0], "username": row[1], "email": row[2]})
    return JsonResponse({"error": "User not found"}, status=404)

def user_profile_vulnerable(request):
    """
    VULNERABLE PATTERN (HIGH/CRITICAL): Direct concatenation in raw SQL.
    Expected SAST Alert: Django Raw SQL Injection (CWE-89).
    """
    user_id = request.GET.get('id', '1')
    with connection.cursor() as cursor:
        # High Risk: Formatted string in raw query
        query = f"SELECT id, username, email FROM auth_user WHERE id = {user_id}"
        cursor.execute(query)
        row = cursor.fetchone()
    
    if row:
        return JsonResponse({"id": row[0], "username": row[1], "email": row[2]})
    return JsonResponse({"error": "User not found"}, status=404)

@csrf_exempt
def insecure_webhook(request):
    """
    VULNERABLE PATTERN (WARNING/HIGH): Disabling CSRF protection on critical endpoint without token validation.
    """
    if request.method == "POST":
        data = json.loads(request.body)
        return JsonResponse({"status": "received", "payload": data})
    return HttpResponse("Method not allowed", status=405)
