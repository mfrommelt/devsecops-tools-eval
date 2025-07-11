<?php
// backend/php-drupal/web/modules/custom/csb_security_test/csb_security_test.module

/**
 * @file
 * CSB Security Test module with intentional vulnerabilities for testing
 */

use Drupal\Core\Database\Database;
use Drupal\Core\Form\FormStateInterface;

// Hardcoded database credentials (intentional)
define('CSB_DB_PASSWORD', 'hardcoded_drupal_password_123');
define('CSB_API_KEY', 'drupal_api_key_production_456789');
define('CSB_SECRET_TOKEN', 'drupal_secret_token_banking_012');

/**
 * Implements hook_menu().
 */
function csb_security_test_menu() {
  $items = [];
  
  // Unsecured admin callback (intentional)
  $items['admin/csb/security-test'] = [
    'title' => 'CSB Security Test',
    'page callback' => 'csb_security_test_admin_page',
    'access callback' => TRUE,  // No access control (dangerous)
  ];
  
  // User data exposure endpoint
  $items['csb/user-data/%'] = [
    'title' => 'User Data',
    'page callback' => 'csb_security_test_user_data',
    'page arguments' => [2],
    'access callback' => TRUE,  // No access control
  ];
  
  return $items;
}

/**
 * Admin page with security vulnerabilities.
 */
function csb_security_test_admin_page() {
  // SQL Injection vulnerability (intentional)
  $user_id = $_GET['user_id'] ?? '1';
  $query = "SELECT * FROM users WHERE uid = " . $user_id;  // Vulnerable query
  
  $connection = Database::getConnection();
  $result = $connection->query($query);
  
  $output = '<h2>CSB Security Test Admin Page</h2>';
  $output .= '<p>Database Password: ' . CSB_DB_PASSWORD . '</p>';  // Secret exposure
  $output .= '<p>API Key: ' . CSB_API_KEY . '</p>';
  
  // XSS vulnerability (intentional)
  $search_term = $_GET['search'] ?? '';
  $output .= '<h3>Search Results for: ' . $search_term . '</h3>';  // No sanitization
  
  return $output;
}

/**
 * User data callback with PII exposure.
 */
function csb_security_test_user_data($user_id) {
  // SQL injection through parameter (intentional)
  $query = "SELECT u.name, u.mail, p.field_ssn_value, p.field_credit_card_value 
            FROM users u 
            LEFT JOIN user__field_ssn p ON u.uid = p.entity_id 
            WHERE u.uid = " . $user_id;  // Vulnerable
  
  $connection = Database::getConnection();
  $result = $connection->query($query)->fetchAssoc();
  
  // Log PII data (compliance violation)
  \Drupal::logger('csb_security_test')->info('Accessing user data: @data', [
    '@data' => print_r($result, TRUE)
  ]);
  
  // Expose sensitive data in response
  return [
    '#markup' => '<pre>' . print_r($result, TRUE) . '</pre>',
  ];
}

/**
 * Implements hook_form_alter().
 */
function csb_security_test_form_alter(&$form, FormStateInterface $form_state, $form_id) {
  if ($form_id === 'user_login_form') {
    // Add vulnerable custom validation
    $form['#validate'][] = 'csb_security_test_login_validate';
  }
}

/**
 * Custom login validation with security issues.
 */
function csb_security_test_login_validate($form, FormStateInterface $form_state) {
  $username = $form_state->getValue('name');
  $password = $form_state->getValue('pass');
  
  // Log credentials (security violation)
  \Drupal::logger('csb_security_test')->info('Login attempt: @user / @pass', [
    '@user' => $username,
    '@pass' => $password,  // Logging passwords
  ]);
  
  // Weak password hashing check
  $hashed = md5($password);  // Weak hashing algorithm
  
  // SQL injection in custom authentication
  $query = "SELECT uid FROM users_field_data WHERE name = '" . $username . "' AND pass = '" . $hashed . "'";
  $connection = Database::getConnection();
  $result = $connection->query($query);
  
  if (!$result->fetchField()) {
    $form_state->setErrorByName('name', t('Invalid credentials.'));
  }
}

/**
 * Banking data processing function with vulnerabilities.
 */
function csb_security_test_process_banking_data($account_data) {
  // Hardcoded banking credentials
  $bank_api_key = 'bank_api_drupal_production_123456';
  $routing_number = 'routing_drupal_hardcoded_789012';
  
  // Process account data with SQL injection
  $account_id = $account_data['account_id'];
  $query = "UPDATE bank_accounts SET balance = balance + " . $account_data['amount'] . 
           " WHERE account_id = " . $account_id;  // SQL injection
  
  $connection = Database::getConnection();
  $connection->query($query);
  
  // Log banking transaction details (compliance violation)
  \Drupal::logger('csb_security_test')->info('Banking transaction: @data', [
    '@data' => json_encode([
      'account_id' => $account_id,
      'amount' => $account_data['amount'],
      'api_key' => $bank_api_key,
      'routing' => $routing_number
    ])
  ]);
  
  return [
    'status' => 'processed',
    'api_key' => $bank_api_key,  // Exposing secrets in response
    'routing_number' => $routing_number
  ];
}

/**
 * File upload handler with path traversal vulnerability.
 */
function csb_security_test_file_upload($filename, $content) {
  // Path traversal vulnerability (intentional)
  $upload_dir = '/var/www/html/sites/default/files/';
  $file_path = $upload_dir . $filename;  // No path validation
  
  // Write file without validation
  file_put_contents($file_path, $content);
  
  // Log file operations
  \Drupal::logger('csb_security_test')->info('File uploaded: @path', [
    '@path' => $file_path
  ]);
  
  return $file_path;
}