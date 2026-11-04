import type { Account, LoginResponse } from "./types";

const TOKEN_KEY = "garage_access_token";
const ACCOUNT_KEY = "garage_account";
const REMEMBERED_USERNAME_KEY = "garage_remembered_username";

export interface StoredSession {
  account: Account;
}

function clearStorage(storage: Storage) {
  storage.removeItem(TOKEN_KEY);
  storage.removeItem(ACCOUNT_KEY);
}

function readFrom(storage: Storage): StoredSession | null {
  storage.removeItem(TOKEN_KEY); // Migrate legacy browser sessions to HttpOnly cookies.
  const accountJson = storage.getItem(ACCOUNT_KEY);
  if (!accountJson) return null;

  try {
    return { account: JSON.parse(accountJson) as Account };
  } catch {
    clearStorage(storage);
    return null;
  }
}

export function readSession(): StoredSession | null {
  return readFrom(localStorage) ?? readFrom(sessionStorage);
}

export function saveSession(response: LoginResponse, remember: boolean): StoredSession {
  clearSession();
  const storage = remember ? localStorage : sessionStorage;
  storage.setItem(ACCOUNT_KEY, JSON.stringify(response.account));
  return { account: response.account };
}

export function updateStoredAccount(account: Account) {
  const storage = localStorage.getItem(ACCOUNT_KEY) ? localStorage : sessionStorage;
  storage.setItem(ACCOUNT_KEY, JSON.stringify(account));
}

export function clearSession() {
  clearStorage(localStorage);
  clearStorage(sessionStorage);
}

export function readRememberedUsername(): string {
  return localStorage.getItem(REMEMBERED_USERNAME_KEY) ?? "";
}

export function rememberUsername(username: string, remember: boolean) {
  if (remember && username.trim()) {
    localStorage.setItem(REMEMBERED_USERNAME_KEY, username.trim());
  } else {
    localStorage.removeItem(REMEMBERED_USERNAME_KEY);
  }
}
