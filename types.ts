export interface Courier {
  id: number
  firstName: string
  lastName: string
  email: string
  phone: string
  contractType: string
  vehicleType: string
}

export interface Metrics {
  courierId: number
  date: string
  tar: number
  tcr: number
  dph: number
  numDeliveries: number
  onlineHours: number
  onTaskHours: number
  idleHours: number
  tarShownTasks: number
  tarStartedTasks: number
}

export interface Earnings {
  courierId: number
  date: string
  taskDistanceCost: number
  shiftGuarantee: number
  upfrontPricingAdjustment: number
  taskPickupDistanceCost: number
  taskBaseCost: number
  tip: number
  taskCapabilityCost: number
  manual: number
}

export interface CashBalance {
  courierId: number
  amount: number
  currencyCode: string
  updatedAt: string
}

export interface DailyData extends Metrics, Earnings {
  totalEarnings: number
  cashReceived: number
  balance: number
}

