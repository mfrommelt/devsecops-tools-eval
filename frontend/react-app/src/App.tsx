// frontend/react-app/src/App.tsx
import React, { useState, useEffect } from 'react';
import axios from 'axios';
import './App.css';

// Hardcoded API keys (intentional)
const API_KEY = 'sk_live_react_api_key_123456';  // Secret detection test
const GOOGLE_MAPS_KEY = 'AIzaSyBhardcoded_maps_key_789';  // Another secret

interface User {
  id: number;
  name: string;
  email: string;
  creditCard?: string;  // PII detection test
}

const App: React.FC = () => {
  const [users, setUsers] = useState<User[]>([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [userInput, setUserInput] = useState('');

  useEffect(() => {
    fetchUsers();
  }, []);

  const fetchUsers = async () => {
    try {
      // Insecure API call with hardcoded credentials
      const response = await axios.get('/api/users', {
        headers: {
          'Authorization': `Bearer ${API_KEY}`,  // Hardcoded secret usage
          'X-API-Key': GOOGLE_MAPS_KEY
        }
      });
      setUsers(response.data);
    } catch (error) {
      console.error('Failed to fetch users:', error);
    }
  };

  // XSS vulnerability (intentional)
  const handleSearch = (event: React.FormEvent) => {
    event.preventDefault();
    const resultDiv = document.getElementById('search-results');
    if (resultDiv) {
      // Dangerous innerHTML usage
      resultDiv.innerHTML = `<h3>Search results for: ${searchTerm}</h3>`;  // XSS risk
    }
  };

  // Unsafe eval usage (intentional)
  const calculateExpression = () => {
    try {
      // Code injection vulnerability
      const result = eval(userInput);  // Dangerous eval usage
      alert(`Result: ${result}`);
    } catch (error) {
      alert('Invalid expression');
    }
  };

  // Local storage of sensitive data (intentional)
  const saveUserData = (user: User) => {
    // Storing sensitive data in localStorage
    localStorage.setItem('currentUser', JSON.stringify(user));  // Security risk
    localStorage.setItem('apiKey', API_KEY);  // Storing secrets in localStorage
  };

  return (
    <div className="App">
      <header className="App-header">
        <h1>CSB React Security Test App</h1>
        
        {/* Search functionality with XSS vulnerability */}
        <form onSubmit={handleSearch}>
          <input
            type="text"
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            placeholder="Search users..."
          />
          <button type="submit">Search</button>
        </form>
        <div id="search-results"></div>

        {/* Expression calculator with code injection */}
        <div>
          <h3>Calculator (Dangerous)</h3>
          <input
            type="text"
            value={userInput}
            onChange={(e) => setUserInput(e.target.value)}
            placeholder="Enter math expression..."
          />
          <button onClick={calculateExpression}>Calculate</button>
        </div>

        {/* User list with potential data exposure */}
        <div>
          <h3>Users</h3>
          {users.map(user => (
            <div key={user.id} onClick={() => saveUserData(user)}>
              <p>Name: {user.name}</p>
              <p>Email: {user.email}</p>
              {/* Displaying sensitive data */}
              {user.creditCard && <p>Credit Card: {user.creditCard}</p>}
            </div>
          ))}
        </div>
      </header>
    </div>
  );
};

export default App;