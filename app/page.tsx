import { Suspense } from "react"
import { format } from "date-fns"
import { CalendarIcon } from "lucide-react"

import { Button } from "@/components/ui/button"
import { Calendar } from "@/components/ui/calendar"
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover"
import { Skeleton } from "@/components/ui/skeleton"
import { getDailyData, getLatestUpdate } from "@/lib/db"
import { formatCurrency, getTimeAgo } from "@/lib/utils"
import { CourierTable } from "./courier-table"

export default async function Page({
  searchParams,
}: {
  searchParams: { id?: string; from?: string; to?: string }
}) {
  const courierId = searchParams.id ? Number.parseInt(searchParams.id) : undefined
  const fromDate = searchParams.from || format(new Date(), "yyyy-MM-01")
  const toDate = searchParams.to || format(new Date(), "yyyy-MM-dd")

  try {
    const [dailyData, latestUpdate] = await Promise.all([getDailyData(courierId, fromDate, toDate), getLatestUpdate()])

    const totalBalance = dailyData.reduce((sum, day) => sum + day.balance, 0)

    return (
      <div className="container mx-auto py-6">
        <div className="mb-8 space-y-4">
          <div className="flex items-center justify-between">
            <h1 className="text-3xl font-bold">Courier Dashboard</h1>
            <div className="text-sm text-muted-foreground">
              Last updated: {latestUpdate ? getTimeAgo(new Date(latestUpdate)) : "Never"}
            </div>
          </div>

          <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
            <div className="flex items-center gap-2">
              <Popover>
                <PopoverTrigger asChild>
                  <Button variant="outline" className="w-[240px] justify-start text-left font-normal">
                    <CalendarIcon className="mr-2 h-4 w-4" />
                    {fromDate} - {toDate}
                  </Button>
                </PopoverTrigger>
                <PopoverContent className="w-auto p-0" align="start">
                  <Calendar
                    mode="range"
                    defaultMonth={new Date(fromDate)}
                    selected={{
                      from: new Date(fromDate),
                      to: new Date(toDate),
                    }}
                    onSelect={(range) => {
                      if (range?.from && range?.to) {
                        const params = new URLSearchParams(window.location.search)
                        params.set("from", format(range.from, "yyyy-MM-dd"))
                        params.set("to", format(range.to, "yyyy-MM-dd"))
                        window.location.search = params.toString()
                      }
                    }}
                  />
                </PopoverContent>
              </Popover>
            </div>

            <div className="flex items-center gap-4">
              <div className="text-2xl font-bold">Balance: {formatCurrency(totalBalance)}</div>
            </div>
          </div>
        </div>

        <Suspense fallback={<Skeleton className="h-[600px] w-full" />}>
          <CourierTable data={dailyData} />
        </Suspense>
      </div>
    )
  } catch (error) {
    return (
      <div className="container mx-auto py-6">
        <div className="rounded-md bg-destructive/15 p-4">
          <div className="flex">
            <div className="flex-1">
              <h3 className="text-sm font-medium text-destructive">Error</h3>
              <div className="mt-1 text-sm text-destructive/90">
                {error instanceof Error ? error.message : "An unexpected error occurred"}
              </div>
            </div>
          </div>
        </div>
      </div>
    )
  }
}

