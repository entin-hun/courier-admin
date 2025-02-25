import { sql } from "@vercel/postgres"
import type { DailyData } from "@/types"

// Verify database connection
async function verifyConnection() {
  try {
    await sql`SELECT NOW();`
    console.log("Database connection successful")
  } catch (error) {
    console.error("Database connection failed:", error)
    throw new Error("Failed to connect to database. Please check your connection string.")
  }
}

export async function getDailyData(courierId?: number, fromDate?: string, toDate?: string) {
  try {
    await verifyConnection()

    const courierFilter = courierId ? sql`AND m.courier_id = ${courierId}` : sql``
    const dateFilter =
      fromDate && toDate
        ? sql`AND m.date BETWEEN ${fromDate} AND ${toDate}`
        : sql`AND m.date >= DATE_TRUNC('month', CURRENT_DATE)`

    const result = await sql`
      WITH daily_data AS (
        SELECT 
          m.courier_id,
          m.date,
          m.tar,
          m.tcr,
          m.dph,
          m.num_deliveries,
          m.online_hours,
          m.on_task_hours,
          m.idle_hours,
          m.tar_shown_tasks,
          m.tar_started_tasks,
          e.task_distance_cost,
          e.shift_guarantee,
          e.upfront_pricing_adjustment,
          e.task_pickup_distance_cost,
          e.task_base_cost,
          e.tip,
          e.task_capability_cost,
          e.manual_adjustment,
          COALESCE(cb.amount, 0) as cash_received,
          (e.task_distance_cost + e.shift_guarantee + e.upfront_pricing_adjustment + 
           e.task_pickup_distance_cost + e.task_base_cost + e.tip + 
           e.task_capability_cost + e.manual_adjustment) as total_earnings
        FROM metrics m
        LEFT JOIN earnings e ON m.courier_id = e.courier_id AND m.date = e.date
        LEFT JOIN cash_balances cb ON m.courier_id = cb.courier_id
        WHERE 1=1 ${courierFilter} ${dateFilter}
      )
      SELECT 
        *,
        total_earnings - cash_received as balance
      FROM daily_data
      ORDER BY date DESC;
    `

    return result.rows as DailyData[]
  } catch (error) {
    console.error("Error fetching daily data:", error)
    throw new Error("Failed to fetch courier data. Please try again later.")
  }
}

export async function getLatestUpdate() {
  try {
    await verifyConnection()

    const result = await sql`
      SELECT MAX(updated_at) as latest_update
      FROM (
        SELECT MAX(tar_updated_at) as updated_at FROM metrics
        UNION ALL
        SELECT MAX(updated_at) FROM earnings
        UNION ALL
        SELECT MAX(updated_at) FROM cash_balances
      ) updates;
    `

    return result.rows[0].latest_update
  } catch (error) {
    console.error("Error fetching latest update:", error)
    throw new Error("Failed to fetch latest update time. Please try again later.")
  }
}

