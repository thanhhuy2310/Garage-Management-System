import { useCallback, useEffect, useState } from "react"
import { errorMessage } from "../api/client"

export function useGarageQuery<T>(query: (signal: AbortSignal) => Promise<T>) {
  const [data, setData] = useState<T | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState("")
  const [version, setVersion] = useState(0)
  const reload = useCallback(() => setVersion((value) => value + 1), [])

  useEffect(() => {
    const controller = new AbortController()
    setLoading(true)
    setError("")
    setData(null)
    query(controller.signal)
      .then((result) => {
        if (!controller.signal.aborted) setData(result)
      })
      .catch((reason: unknown) => {
        if (!controller.signal.aborted)
          setError(
            errorMessage(reason, "Không tải được dữ liệu. Vui lòng thử lại."),
          )
      })
      .finally(() => {
        if (!controller.signal.aborted) setLoading(false)
      })
    return () => controller.abort()
  }, [query, version])

  return { data, loading, error, reload, setData }
}
