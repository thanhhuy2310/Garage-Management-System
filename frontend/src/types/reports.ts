export interface ReportOverview {
  from: string
  to: string
  billing: {
    invoiced: number
    collected: number
    outstanding: number
    invoiceCount: number
    paidInvoiceCount: number
  }
  repairs: {
    opened: number
    completed: number
    inProgress: number
    completionRate: number
    averageHandlingHours: number
  }
  inventory: {
    imported: number
    exported: number
    currentStock: number
    lowStockParts: number
    outOfStockParts: number
  }
  vehicleStatuses: { status: string; count: number }[]
  trends: {
    period: string
    invoiced: number
    collected: number
    completedRepairs: number
  }[]
  partMovements: {
    partId: number
    partName: string
    imported: number
    exported: number
    currentStock: number
  }[]
  technicianPerformance: {
    employeeId: number
    employeeName: string
    assigned: number
    completed: number
    completionRate: number
    averageHandlingHours: number
  }[]
}
