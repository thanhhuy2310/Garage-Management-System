import type { Account, LoginResponse } from "./types";

const TOKEN_KEY = "garage_access_token";
const ACCOUNT_KEY = "garage_account";

export interface StoredSession {
  accessToken: string;
  account: Account;
}

function clearStorage(storage: Storage) {
  storage.removeItem(TOKEN_KEY);
  storage.removeItem(ACCOUNT_KEY);
}

function readFrom(storage: Storage): StoredSession | null {
  const accessToken = storage.getItem(TOKEN_KEY);
  const accountJson = storage.getItem(ACCOUNT_KEY);
  if (!accessToken || !accountJson) return null;

  try {
    return { accessToken, account: JSON.parse(accountJson) as Account };
  } catch {
    clearStorage(storage);
    return null;
  }
}

export function readSession(): StoredSession | null {
  return readFrom(localStorage) ?? readFrom(sessionStorage);
}

export function getAccessToken(): string | null {
  return localStorage.getItem(TOKEN_KEY) ?? sessionStorage.getItem(TOKEN_KEY);
}

export function saveSession(response: LoginResponse, remember: boolean): StoredSession {
  clearSession();
  const storage = remember ? localStorage : sessionStorage;
  storage.setItem(TOKEN_KEY, response.accessToken);
  storage.setItem(ACCOUNT_KEY, JSON.stringify(response.account));
  return { accessToken: response.accessToken, account: response.account };
}

export function updateStoredAccount(account: Account) {
  const storage = localStorage.getItem(TOKEN_KEY) ? localStorage : sessionStorage;
  storage.setItem(ACCOUNT_KEY, JSON.stringify(account));
}

export function clearSession() {
  clearStorage(localStorage);
  clearStorage(sessionStorage);
}
