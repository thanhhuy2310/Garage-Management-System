import { api, unwrap } from "./client"
import type { ApiResponse } from "./types"
import type { ReportOverview } from "../types/reports"

export const reportsApi = {
  async overview(from: string, to: string, signal?: AbortSignal) {
    return unwrap(
      await api.get<ApiResponse<ReportOverview>>("/api/reports/overview", {
        params: { from, to },
        signal,
      }),
    )
  },
}
