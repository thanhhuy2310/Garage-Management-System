import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App'
import './index.css'
import { validateMockRelationships } from './mock/validate'

const mockRelationshipErrors = validateMockRelationships()
if (mockRelationshipErrors.length > 0) {
  throw new Error(`Dữ liệu mock không hợp lệ:\n${mockRelationshipErrors.join('\n')}`)
}

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
)
