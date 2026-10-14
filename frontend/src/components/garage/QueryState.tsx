import { Button, Card } from "../ui"

export function QueryState({
  loading,
  error,
  onRetry,
}: {
  loading: boolean
  error: string
  onRetry: () => void
}) {
  if (loading)
    return (
      <p className="py-12 text-center text-muted-foreground" role="status">
        Đang tải dữ liệu...
      </p>
    )
  if (!error) return null
  return (
    <Card className="space-y-3 p-5">
      <p role="alert" className="text-sm text-danger">
        {error}
      </p>
      <Button variant="outline" onClick={onRetry}>
        Thử lại
      </Button>
    </Card>
  )
}
