// frontend/angular-app/src/app/app.component.ts
import { Component, OnInit } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { DomSanitizer, SafeHtml } from '@angular/platform-browser';

// Hardcoded secrets (intentional)
const API_ENDPOINT = 'https://api.csb.com/v1';
const SECRET_TOKEN = 'bearer_token_angular_app_456789';  // Secret detection test
const AWS_ACCESS_KEY = 'AKIAIOSFODNN7EXAMPLE123';  // AWS key detection

interface UserData {
  id: number;
  name: string;
  email: string;
  ssn?: string;  // PII detection test
}

@Component({
  selector: 'app-root',
  template: `
    <div class="container">
      <h1>CSB Angular Security Test App</h1>
      
      <!-- XSS vulnerability through bypassing sanitization -->
      <div [innerHTML]="unsafeHtml"></div>
      
      <!-- Form with potential injection -->
      <form (ngSubmit)="submitData()">
        <input [(ngModel)]="userInput" placeholder="Enter data">
        <button type="submit">Submit</button>
      </form>
      
      <!-- Display sensitive data -->
      <div *ngFor="let user of users">
        <p>{{user.name}} - {{user.email}}</p>
        <p *ngIf="user.ssn">SSN: {{user.ssn}}</p>
      </div>
    </div>
  `
})
export class AppComponent implements OnInit {
  title = 'csb-angular-security-test';
  users: UserData[] = [];
  userInput = '';
  unsafeHtml: SafeHtml = '';

  constructor(
    private http: HttpClient,
    private sanitizer: DomSanitizer
  ) {}

  ngOnInit() {
    this.loadUsers();
    this.setupUnsafeContent();
  }

  loadUsers() {
    // Insecure HTTP call with hardcoded credentials
    const headers = {
      'Authorization': SECRET_TOKEN,  // Hardcoded secret usage
      'X-AWS-Access-Key': AWS_ACCESS_KEY
    };

    this.http.get<UserData[]>(`${API_ENDPOINT}/users`, { headers })
      .subscribe(
        data => this.users = data,
        error => console.error('Error loading users:', error)
      );
  }

  submitData() {
    // Unsafe evaluation (intentional)
    try {
      const result = eval(`"Result: " + ${this.userInput}`);  // Code injection
      alert(result);
    } catch (error) {
      console.error('Evaluation error:', error);
    }

    // Store sensitive data in localStorage
    localStorage.setItem('userInput', this.userInput);
    localStorage.setItem('apiToken', SECRET_TOKEN);  // Storing secrets
  }

  setupUnsafeContent() {
    // Bypassing Angular's sanitization (dangerous)
    const unsafeContent = '<script>alert("XSS")</script><p>Unsafe content</p>';
    this.unsafeHtml = this.sanitizer.bypassSecurityTrustHtml(unsafeContent);  // XSS risk
  }

  // Weak random number generation
  generateSessionId(): string {
    return Math.random().toString(36);  // Cryptographically weak
  }

  // Insecure cookie handling
  setCookie(name: string, value: string) {
    document.cookie = `${name}=${value}`;  // No secure/httpOnly flags
  }
}