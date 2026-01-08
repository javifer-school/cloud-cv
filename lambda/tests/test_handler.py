"""
Unit Tests for Visit Counter Lambda Handler
============================================

This module contains comprehensive tests for the Lambda function
that handles visit counting for the Cloud CV website.
"""

import json
import pytest
from unittest.mock import MagicMock, patch
from botocore.exceptions import ClientError

# Import the handler module
import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'visit_counter'))

import handler


class TestGetVisitorIP:
    """Tests for the get_visitor_ip function."""
    
    def test_get_ip_from_http_api_v2(self, api_gateway_event_get):
        """Test extracting IP from HTTP API v2 format."""
        ip = handler.get_visitor_ip(api_gateway_event_get)
        assert ip == '192.168.1.100'
    
    def test_get_ip_from_x_forwarded_for(self):
        """Test extracting IP from X-Forwarded-For header."""
        event = {
            'headers': {
                'x-forwarded-for': '10.0.0.1, 192.168.1.1, 172.16.0.1'
            },
            'requestContext': {}
        }
        ip = handler.get_visitor_ip(event)
        assert ip == '10.0.0.1'
    
    def test_get_ip_unknown_when_missing(self):
        """Test returning 'unknown' when IP cannot be determined."""
        event = {
            'headers': {},
            'requestContext': {}
        }
        ip = handler.get_visitor_ip(event)
        assert ip == 'unknown'


class TestCORSHeaders:
    """Tests for CORS header generation."""
    
    def test_cors_headers_allowed_origin(self, api_gateway_event_get):
        """Test CORS headers with allowed origin."""
        headers = handler.get_cors_headers(api_gateway_event_get)
        
        assert headers['Access-Control-Allow-Origin'] == 'https://cv.aws10.atercates.cat'
        assert 'GET' in headers['Access-Control-Allow-Methods']
        assert 'POST' in headers['Access-Control-Allow-Methods']
    
    def test_cors_headers_localhost_wildcard(self):
        """Test CORS headers with localhost wildcard pattern."""
        event = {
            'headers': {
                'origin': 'http://localhost:3000'
            }
        }
        headers = handler.get_cors_headers(event)
        assert headers['Access-Control-Allow-Origin'] == 'http://localhost:3000'
    
    def test_cors_headers_unknown_origin(self):
        """Test CORS headers with unknown origin."""
        event = {
            'headers': {
                'origin': 'https://malicious-site.com'
            }
        }
        headers = handler.get_cors_headers(event)
        # Should default to * or first allowed
        assert 'Access-Control-Allow-Origin' in headers


class TestResponse:
    """Tests for the response helper function."""
    
    def test_response_format(self, api_gateway_event_get):
        """Test response has correct format."""
        resp = handler.response(200, {'test': 'data'}, api_gateway_event_get)
        
        assert resp['statusCode'] == 200
        assert 'headers' in resp
        assert 'body' in resp
        assert json.loads(resp['body']) == {'test': 'data'}
    
    def test_response_error_code(self, api_gateway_event_get):
        """Test response with error status code."""
        resp = handler.response(500, {'error': 'Test error'}, api_gateway_event_get)
        
        assert resp['statusCode'] == 500
        body = json.loads(resp['body'])
        assert body['error'] == 'Test error'


class TestHandleGet:
    """Tests for GET request handling."""
    
    @patch('handler.get_table')
    @patch('handler.get_total_visits')
    @patch('handler.get_unique_visitors')
    def test_handle_get_existing_visitor(
        self, 
        mock_unique, 
        mock_total, 
        mock_get_table,
        api_gateway_event_get,
        sample_visitor_data
    ):
        """Test GET request for existing visitor."""
        mock_table = MagicMock()
        mock_table.get_item.return_value = {'Item': sample_visitor_data}
        mock_get_table.return_value = mock_table
        mock_total.return_value = 100
        mock_unique.return_value = 25
        
        response = handler.handle_get(api_gateway_event_get)
        
        assert response['statusCode'] == 200
        body = json.loads(response['body'])
        assert body['total_visits'] == 100
        assert body['unique_visitors'] == 25
        assert body['visitor_ip'] == '192.168.1.100'
        assert body['visitor_visits'] == 5
    
    @patch('handler.get_table')
    @patch('handler.get_total_visits')
    @patch('handler.get_unique_visitors')
    def test_handle_get_new_visitor(
        self,
        mock_unique,
        mock_total,
        mock_get_table,
        api_gateway_event_get
    ):
        """Test GET request for new visitor (not in database)."""
        mock_table = MagicMock()
        mock_table.get_item.return_value = {}  # No Item
        mock_get_table.return_value = mock_table
        mock_total.return_value = 50
        mock_unique.return_value = 10
        
        response = handler.handle_get(api_gateway_event_get)
        
        assert response['statusCode'] == 200
        body = json.loads(response['body'])
        assert body['visitor_visits'] == 0
        assert body['first_visit'] is None
        assert body['last_visit'] is None


class TestHandlePost:
    """Tests for POST request handling."""
    
    @patch('handler.get_table')
    @patch('handler.get_total_visits')
    @patch('handler.get_unique_visitors')
    def test_handle_post_new_visit(
        self,
        mock_unique,
        mock_total,
        mock_get_table,
        api_gateway_event_post
    ):
        """Test POST request to register new visit."""
        mock_table = MagicMock()
        mock_table.update_item.return_value = {
            'Attributes': {
                'visitor_ip': '192.168.1.100',
                'visit_count': 1,
                'first_visit': '2026-01-08T10:30:00+00:00',
                'last_visit': '2026-01-08T10:30:00+00:00'
            }
        }
        mock_get_table.return_value = mock_table
        mock_total.return_value = 101
        mock_unique.return_value = 26
        
        response = handler.handle_post(api_gateway_event_post)
        
        assert response['statusCode'] == 200
        body = json.loads(response['body'])
        assert body['message'] == 'Visit registered successfully'
        assert body['visitor_visits'] == 1
        assert body['total_visits'] == 101
    
    @patch('handler.get_table')
    def test_handle_post_dynamodb_error(
        self,
        mock_get_table,
        api_gateway_event_post
    ):
        """Test POST request when DynamoDB fails."""
        mock_table = MagicMock()
        mock_table.update_item.side_effect = ClientError(
            {'Error': {'Code': 'InternalError', 'Message': 'Test error'}},
            'UpdateItem'
        )
        mock_get_table.return_value = mock_table
        
        response = handler.handle_post(api_gateway_event_post)
        
        assert response['statusCode'] == 500
        body = json.loads(response['body'])
        assert 'error' in body


class TestLambdaHandler:
    """Tests for the main Lambda handler."""
    
    @patch('handler.handle_get')
    def test_handler_routes_get(
        self,
        mock_handle_get,
        api_gateway_event_get,
        mock_context
    ):
        """Test handler routes GET requests correctly."""
        mock_handle_get.return_value = {
            'statusCode': 200,
            'body': json.dumps({'test': 'get'})
        }
        
        response = handler.lambda_handler(api_gateway_event_get, mock_context)
        
        mock_handle_get.assert_called_once()
    
    @patch('handler.handle_post')
    def test_handler_routes_post(
        self,
        mock_handle_post,
        api_gateway_event_post,
        mock_context
    ):
        """Test handler routes POST requests correctly."""
        mock_handle_post.return_value = {
            'statusCode': 200,
            'body': json.dumps({'test': 'post'})
        }
        
        response = handler.lambda_handler(api_gateway_event_post, mock_context)
        
        mock_handle_post.assert_called_once()
    
    def test_handler_options_request(
        self,
        api_gateway_event_options,
        mock_context
    ):
        """Test handler responds to OPTIONS (CORS preflight)."""
        response = handler.lambda_handler(api_gateway_event_options, mock_context)
        
        assert response['statusCode'] == 200
        assert 'Access-Control-Allow-Origin' in response['headers']
    
    def test_handler_unsupported_method(self, mock_context):
        """Test handler returns 405 for unsupported methods."""
        event = {
            'requestContext': {
                'http': {
                    'method': 'DELETE'
                }
            },
            'headers': {}
        }
        
        response = handler.lambda_handler(event, mock_context)
        
        assert response['statusCode'] == 405
        body = json.loads(response['body'])
        assert 'error' in body


class TestDynamoDBOperations:
    """Tests for DynamoDB operations."""
    
    @patch('handler.get_table')
    def test_get_total_visits(self, mock_get_table):
        """Test calculating total visits."""
        mock_table = MagicMock()
        mock_table.scan.return_value = {
            'Items': [
                {'visit_count': 10},
                {'visit_count': 20},
                {'visit_count': 30}
            ]
        }
        mock_get_table.return_value = mock_table
        
        total = handler.get_total_visits()
        
        assert total == 60
    
    @patch('handler.get_table')
    def test_get_total_visits_with_pagination(self, mock_get_table):
        """Test calculating total visits with pagination."""
        mock_table = MagicMock()
        mock_table.scan.side_effect = [
            {
                'Items': [{'visit_count': 10}],
                'LastEvaluatedKey': {'visitor_ip': 'last-key'}
            },
            {
                'Items': [{'visit_count': 20}]
            }
        ]
        mock_get_table.return_value = mock_table
        
        total = handler.get_total_visits()
        
        assert total == 30
        assert mock_table.scan.call_count == 2
    
    @patch('handler.get_table')
    def test_get_unique_visitors(self, mock_get_table):
        """Test getting unique visitor count."""
        mock_table = MagicMock()
        mock_table.scan.return_value = {'Count': 42}
        mock_get_table.return_value = mock_table
        
        count = handler.get_unique_visitors()
        
        assert count == 42
        mock_table.scan.assert_called_once_with(Select='COUNT')


class TestIntegration:
    """Integration-style tests (with mocked AWS)."""
    
    @patch('handler.get_table')
    def test_full_visit_flow(self, mock_get_table, mock_context):
        """Test complete visit registration flow."""
        mock_table = MagicMock()
        
        # First call: check visitor (new)
        mock_table.get_item.return_value = {}
        
        # Second call: update visitor
        mock_table.update_item.return_value = {
            'Attributes': {
                'visitor_ip': '192.168.1.100',
                'visit_count': 1,
                'first_visit': '2026-01-08T10:30:00+00:00',
                'last_visit': '2026-01-08T10:30:00+00:00'
            }
        }
        
        # Third call: get total
        mock_table.scan.side_effect = [
            {'Items': [{'visit_count': 1}]},  # For total
            {'Count': 1}  # For unique
        ]
        
        mock_get_table.return_value = mock_table
        
        # Register visit
        post_event = {
            'requestContext': {
                'http': {
                    'method': 'POST',
                    'sourceIp': '192.168.1.100'
                }
            },
            'headers': {'origin': 'https://cv.aws10.atercates.cat'}
        }
        
        response = handler.lambda_handler(post_event, mock_context)
        
        assert response['statusCode'] == 200
        body = json.loads(response['body'])
        assert body['visitor_visits'] == 1
        assert 'total_visits' in body
