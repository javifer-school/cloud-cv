"""
Pytest Fixtures for Lambda Tests
================================

This module contains shared fixtures for testing the Lambda function.
"""

import os
import pytest
from unittest.mock import MagicMock, patch


@pytest.fixture(autouse=True)
def set_env_vars():
    """Set environment variables for testing."""
    os.environ['DYNAMODB_TABLE'] = 'test-cv-visit-counter'
    os.environ['ALLOWED_ORIGINS'] = 'https://cv.aws10.atercates.cat,http://localhost:3000'
    yield
    # Cleanup
    if 'DYNAMODB_TABLE' in os.environ:
        del os.environ['DYNAMODB_TABLE']
    if 'ALLOWED_ORIGINS' in os.environ:
        del os.environ['ALLOWED_ORIGINS']


@pytest.fixture
def mock_dynamodb_table():
    """Create a mock DynamoDB table."""
    with patch('handler.dynamodb') as mock_dynamodb:
        mock_table = MagicMock()
        mock_dynamodb.Table.return_value = mock_table
        yield mock_table


@pytest.fixture
def api_gateway_event_get():
    """Create a mock API Gateway GET event (HTTP API v2 format)."""
    return {
        'version': '2.0',
        'routeKey': 'GET /visits',
        'rawPath': '/visits',
        'rawQueryString': '',
        'headers': {
            'accept': 'application/json',
            'content-type': 'application/json',
            'host': 'api.example.com',
            'origin': 'https://cv.aws10.atercates.cat',
            'x-forwarded-for': '192.168.1.100'
        },
        'requestContext': {
            'accountId': '123456789012',
            'apiId': 'abc123',
            'domainName': 'api.example.com',
            'domainPrefix': 'api',
            'http': {
                'method': 'GET',
                'path': '/visits',
                'protocol': 'HTTP/1.1',
                'sourceIp': '192.168.1.100',
                'userAgent': 'Mozilla/5.0'
            },
            'requestId': 'request-id-123',
            'routeKey': 'GET /visits',
            'stage': '$default',
            'time': '08/Jan/2026:10:30:00 +0000',
            'timeEpoch': 1767875400000
        },
        'isBase64Encoded': False
    }


@pytest.fixture
def api_gateway_event_post():
    """Create a mock API Gateway POST event (HTTP API v2 format)."""
    return {
        'version': '2.0',
        'routeKey': 'POST /visits',
        'rawPath': '/visits',
        'rawQueryString': '',
        'headers': {
            'accept': 'application/json',
            'content-type': 'application/json',
            'host': 'api.example.com',
            'origin': 'https://cv.aws10.atercates.cat',
            'x-forwarded-for': '192.168.1.100'
        },
        'requestContext': {
            'accountId': '123456789012',
            'apiId': 'abc123',
            'domainName': 'api.example.com',
            'domainPrefix': 'api',
            'http': {
                'method': 'POST',
                'path': '/visits',
                'protocol': 'HTTP/1.1',
                'sourceIp': '192.168.1.100',
                'userAgent': 'Mozilla/5.0'
            },
            'requestId': 'request-id-456',
            'routeKey': 'POST /visits',
            'stage': '$default',
            'time': '08/Jan/2026:10:30:00 +0000',
            'timeEpoch': 1767875400000
        },
        'body': '{}',
        'isBase64Encoded': False
    }


@pytest.fixture
def api_gateway_event_options():
    """Create a mock API Gateway OPTIONS event (CORS preflight)."""
    return {
        'version': '2.0',
        'routeKey': 'OPTIONS /visits',
        'rawPath': '/visits',
        'rawQueryString': '',
        'headers': {
            'accept': '*/*',
            'host': 'api.example.com',
            'origin': 'https://cv.aws10.atercates.cat',
            'access-control-request-method': 'POST',
            'access-control-request-headers': 'content-type'
        },
        'requestContext': {
            'accountId': '123456789012',
            'apiId': 'abc123',
            'domainName': 'api.example.com',
            'domainPrefix': 'api',
            'http': {
                'method': 'OPTIONS',
                'path': '/visits',
                'protocol': 'HTTP/1.1',
                'sourceIp': '192.168.1.100',
                'userAgent': 'Mozilla/5.0'
            },
            'requestId': 'request-id-789',
            'routeKey': 'OPTIONS /visits',
            'stage': '$default',
            'time': '08/Jan/2026:10:30:00 +0000',
            'timeEpoch': 1767875400000
        },
        'isBase64Encoded': False
    }


@pytest.fixture
def mock_context():
    """Create a mock Lambda context."""
    context = MagicMock()
    context.function_name = 'cv-visit-counter'
    context.function_version = '$LATEST'
    context.invoked_function_arn = 'arn:aws:lambda:eu-west-1:123456789012:function:cv-visit-counter'
    context.memory_limit_in_mb = 128
    context.aws_request_id = 'request-id-abc'
    context.log_group_name = '/aws/lambda/cv-visit-counter'
    context.log_stream_name = '2026/01/08/[$LATEST]abc123'
    context.get_remaining_time_in_millis = MagicMock(return_value=10000)
    return context


@pytest.fixture
def sample_visitor_data():
    """Sample visitor data from DynamoDB."""
    return {
        'visitor_ip': '192.168.1.100',
        'visit_count': 5,
        'first_visit': '2026-01-01T10:00:00+00:00',
        'last_visit': '2026-01-08T10:30:00+00:00'
    }
