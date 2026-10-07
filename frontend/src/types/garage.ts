export interface GarageService {
  id: number
  name: string
  type: string | null
  unitPrice: number
  description: string | null
}

export type ServiceRequest = Omit<GarageService, "id">

export interface Technician {
  id: number
  fullName: string
}

export interface TechnicianAssignment {
  repairOrderId: number
  technician: Technician
  assignedAt: string
  notes: string | null
}

export interface AssignmentRequest {
  technicianId: number
  notes: string | null
}

export interface RepairOrder {
  id: number
  receptionId: number
  createdAt: string
  startedAt: string | null
  completedAt: string | null
  status: string
  result: string | null
  licensePlate: string
  brand: string | null
  model: string | null
  customerName: string
  customerRequest: string | null
  initialCondition: string | null
}

export interface RepairServiceLine {
  id: number
  name: string
  quantity: number
  unitPrice: number
  status: string | null
}

export interface RepairOrderDetail {
  order: RepairOrder
  services: RepairServiceLine[]
  assignments: TechnicianAssignment[]
  progress: RepairProgress[]
}

export interface RepairProgress {
  id: number
  serviceId: number | null
  status: string
  notes: string
  updatedBy: string
  createdAt: string
}

export interface ProgressRequest {
  status: string
  expectedStatus: string
  notes: string
}

export interface ReceptionOption {
  id: number
  licensePlate: string
  customerName: string
}
