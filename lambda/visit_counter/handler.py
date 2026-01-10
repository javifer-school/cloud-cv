"""
Visit Counter Lambda Handler
============================

This Lambda function handles visit counting for the Cloud CV website.
It tracks visitor IPs and their visit counts in DynamoDB.

Endpoints:
- GET /visits: Get total visits and visitor's visit count
- POST /visits: Register a new visit

Environment Variables: 
- DYNAMODB_TABLE: Name of the DynamoDB table
- ALLOWED_ORIGINS: Comma-separated list of allowed CORS origins
"""

import json
import os
import logging
from datetime import datetime, timezone
from typing import Any
from decimal import Decimal

import boto3
from botocore.exceptions import ClientError

# Configure logging 
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# DynamoDB configuration (initialized lazily to avoid import issues in testing)
TABLE_NAME = os.environ.get('DYNAMODB_TABLE', 'cv-visit-counter')
ALLOWED_ORIGINS = os.environ.get('ALLOWED_ORIGINS', '*').split(',')
_dynamodb = None  # Lazy initialization


def get_dynamodb():
    """Get DynamoDB resource (lazy initialization)."""
    global _dynamodb
    if _dynamodb is None:
        _dynamodb = boto3.resource('dynamodb')
    return _dynamodb


class DecimalEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, Decimal):
            return int(obj)
        return super(DecimalEncoder, self).default(obj)


def get_table():
    """Get DynamoDB table resource."""
    dynamodb = get_dynamodb()
    return dynamodb.Table(TABLE_NAME)


def get_visitor_ip(event: dict) -> str:
    """
    Extract visitor IP from the event.
    
    Args:
        event: Lambda event object
        
    Returns:
        Visitor IP address as string
    """
    # Try to get IP from various sources
    request_context = event.get('requestContext', {})
    
    # API Gateway HTTP API v2 format
    if 'http' in request_context:
        return request_context['http'].get('sourceIp', 'unknown')
    
    # API Gateway REST API format
    if 'identity' in request_context:
        return request_context['identity'].get('sourceIp', 'unknown')
    
    # X-Forwarded-For header (when behind a proxy/load balancer)
    headers = event.get('headers', {})
    if headers:
        forwarded_for = headers.get('x-forwarded-for', headers.get('X-Forwarded-For', ''))
        if forwarded_for:
            # Return the first IP in the chain (original client)
            return forwarded_for.split(',')[0].strip()
    
    return 'unknown'


def get_cors_headers(event: dict) -> dict:
    """
    Get CORS headers based on the request origin.
    
    Args:
        event: Lambda event object
        
    Returns:
        Dictionary with CORS headers
    """
    headers = event.get('headers', {})
    origin = headers.get('origin', headers.get('Origin', ''))
    
    # Check if origin is allowed
    allowed_origin = '*'
    if origin:
        for allowed in ALLOWED_ORIGINS:
            if allowed == '*' or allowed == origin:
                allowed_origin = origin
                break
            # Handle wildcard patterns like http://localhost:*
            if '*' in allowed:
                pattern = allowed.replace('*', '')
                if origin.startswith(pattern):
                    allowed_origin = origin
                    break
    
    return {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': allowed_origin,
        'Access-Control-Allow-Headers': 'Content-Type,X-Forwarded-For',
        'Access-Control-Allow-Methods': 'GET,POST,OPTIONS'
    }


def response(status_code: int, body: dict, event: dict) -> dict:
    """
    Create a standardized API response.
    
    Args:
        status_code: HTTP status code
        body: Response body dictionary
        event: Lambda event object (for CORS headers)
        
    Returns:
        API Gateway response object
    """
    return {
        'statusCode': status_code,
        'headers': get_cors_headers(event),
        'body': json.dumps(body, cls=DecimalEncoder)
    }


def get_visitor_data(visitor_ip: str) -> dict | None:
    """
    Get visitor data from DynamoDB.
    
    Args:
        visitor_ip: Visitor's IP address
        
    Returns:
        Visitor data dictionary or None if not found
    """
    table = get_table()
    try:
        result = table.get_item(Key={'visitor_ip': visitor_ip})
        return result.get('Item')
    except ClientError as e:
        logger.error(f"Error getting visitor data: {e}")
        return None


def update_visitor(visitor_ip: str) -> dict:
    """
    Update or create visitor record in DynamoDB.
    
    Args:
        visitor_ip: Visitor's IP address
        
    Returns:
        Updated visitor data
    """
    table = get_table()
    now = datetime.now(timezone.utc).isoformat()
    
    try:
        result = table.update_item(
            Key={'visitor_ip': visitor_ip},
            UpdateExpression='''
                SET visit_count = if_not_exists(visit_count, :zero) + :inc,
                    last_visit = :now,
                    first_visit = if_not_exists(first_visit, :now)
            ''',
            ExpressionAttributeValues={
                ':inc': 1,
                ':zero': 0,
                ':now': now
            },
            ReturnValues='ALL_NEW'
        )
        return result.get('Attributes', {})
    except ClientError as e:
        logger.error(f"Error updating visitor: {e}")
        raise


def get_total_visits() -> int:
    """
    Get total number of visits across all visitors.
    
    Returns:
        Total visit count
    """
    table = get_table()
    total = 0
    
    try:
        # Scan table to sum all visit counts
        response = table.scan(
            ProjectionExpression='visit_count'
        )
        
        for item in response.get('Items', []):
            total += item.get('visit_count', 0)
        
        # Handle pagination
        while 'LastEvaluatedKey' in response:
            response = table.scan(
                ProjectionExpression='visit_count',
                ExclusiveStartKey=response['LastEvaluatedKey']
            )
            for item in response.get('Items', []):
                total += item.get('visit_count', 0)
        
        return total
    except ClientError as e:
        logger.error(f"Error getting total visits: {e}")
        return 0


def get_unique_visitors() -> int:
    """
    Get count of unique visitors.
    
    Returns:
        Number of unique visitors
    """
    table = get_table()
    
    try:
        response = table.scan(Select='COUNT')
        return response.get('Count', 0)
    except ClientError as e:
        logger.error(f"Error getting unique visitors: {e}")
        return 0


def handle_get(event: dict) -> dict:
    """
    Handle GET request - return visit statistics.
    
    Args:
        event: Lambda event object
        
    Returns:
        API response with visit statistics
    """
    visitor_ip = get_visitor_ip(event)
    visitor_data = get_visitor_data(visitor_ip)
    
    data = {
        'total_visits': get_total_visits(),
        'unique_visitors': get_unique_visitors(),
        'visitor_ip': visitor_ip,
        'visitor_visits': visitor_data.get('visit_count', 0) if visitor_data else 0,
        'first_visit': visitor_data.get('first_visit') if visitor_data else None,
        'last_visit': visitor_data.get('last_visit') if visitor_data else None
    }
    
    return response(200, data, event)


def handle_post(event: dict) -> dict:
    """
    Handle POST request - register a new visit.
    
    Args:
        event: Lambda event object
        
    Returns:
        API response with updated visit data
    """
    visitor_ip = get_visitor_ip(event)
    
    try:
        visitor_data = update_visitor(visitor_ip)
        
        data = {
            'message': 'Visit registered successfully',
            'visitor_ip': visitor_ip,
            'visitor_visits': visitor_data.get('visit_count', 1),
            'total_visits': get_total_visits(),
            'unique_visitors': get_unique_visitors()
        }
        
        return response(200, data, event)
    except Exception as e:
        logger.error(f"Error registering visit: {e}")
        return response(500, {'error': 'Failed to register visit'}, event)


def lambda_handler(event: dict, context: Any) -> dict:
    """
    Main Lambda handler function.
    
    Args:
        event: Lambda event object
        context: Lambda context object
        
    Returns:
        API Gateway response object
    """
    logger.info(f"Event: {json.dumps(event)}")
    
    # Get HTTP method
    request_context = event.get('requestContext', {})
    http_method = request_context.get('http', {}).get('method', '')
    
    # Also check for REST API format
    if not http_method:
        http_method = event.get('httpMethod', 'GET')
    
    # Handle OPTIONS (CORS preflight)
    if http_method == 'OPTIONS':
        return response(200, {'message': 'OK'}, event)
    
    # Route to appropriate handler
    if http_method == 'GET':
        return handle_get(event)
    elif http_method == 'POST':
        return handle_post(event)
    else:
        return response(405, {'error': f'Method {http_method} not allowed'}, event)
