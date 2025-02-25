"use client"

import { useState } from "react"
import {
  type ColumnDef,
  type ColumnFiltersState,
  type SortingState,
  type VisibilityState,
  flexRender,
  getCoreRowModel,
  getFilteredRowModel,
  getPaginationRowModel,
  getSortedRowModel,
  useReactTable,
} from "@tanstack/react-table"
import { SlidersHorizontal } from "lucide-react"

import { Button } from "@/components/ui/button"
import {
  DropdownMenu,
  DropdownMenuCheckboxItem,
  DropdownMenuContent,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table"
import type { DailyData } from "@/types"
import { formatCurrency, formatDuration } from "@/lib/utils"

const columns: ColumnDef<DailyData>[] = [
  {
    accessorKey: "date",
    header: "Date",
  },
  {
    accessorKey: "tar",
    header: "TAR",
    cell: ({ row }) => formatCurrency(row.getValue("tar")),
  },
  {
    accessorKey: "tcr",
    header: "TCR",
    cell: ({ row }) => formatCurrency(row.getValue("tcr")),
  },
  {
    accessorKey: "dph",
    header: "DPH",
    cell: ({ row }) => row.getValue("dph"),
  },
  {
    accessorKey: "onlineHours",
    header: "Online Time",
    cell: ({ row }) => formatDuration(row.getValue("onlineHours")),
  },
  {
    accessorKey: "onTaskHours",
    header: "On-Task Time",
    cell: ({ row }) => formatDuration(row.getValue("onTaskHours")),
  },
  {
    accessorKey: "idleHours",
    header: "Idle Time",
    cell: ({ row }) => formatDuration(row.getValue("idleHours")),
  },
  {
    accessorKey: "numDeliveries",
    header: "Deliveries",
  },
  {
    accessorKey: "tarShownTasks",
    header: "Tasks Shown",
  },
  {
    accessorKey: "tarStartedTasks",
    header: "Tasks Started",
  },
  {
    accessorKey: "taskDistanceCost",
    header: "Distance Cost",
    cell: ({ row }) => formatCurrency(row.getValue("taskDistanceCost")),
  },
  {
    accessorKey: "shiftGuarantee",
    header: "Shift Guarantee",
    cell: ({ row }) => formatCurrency(row.getValue("shiftGuarantee")),
  },
  {
    accessorKey: "upfrontPricingAdjustment",
    header: "Pricing Adjustment",
    cell: ({ row }) => formatCurrency(row.getValue("upfrontPricingAdjustment")),
  },
  {
    accessorKey: "taskPickupDistanceCost",
    header: "Pickup Cost",
    cell: ({ row }) => formatCurrency(row.getValue("taskPickupDistanceCost")),
  },
  {
    accessorKey: "taskBaseCost",
    header: "Base Cost",
    cell: ({ row }) => formatCurrency(row.getValue("taskBaseCost")),
  },
  {
    accessorKey: "tip",
    header: "Tips",
    cell: ({ row }) => formatCurrency(row.getValue("tip")),
  },
  {
    accessorKey: "taskCapabilityCost",
    header: "Capability Cost",
    cell: ({ row }) => formatCurrency(row.getValue("taskCapabilityCost")),
  },
  {
    accessorKey: "manual",
    header: "Manual Adj.",
    cell: ({ row }) => formatCurrency(row.getValue("manual")),
  },
]

export function CourierTable({ data }: { data: DailyData[] }) {
  const [sorting, setSorting] = useState<SortingState>([])
  const [columnFilters, setColumnFilters] = useState<ColumnFiltersState>([])
  const [columnVisibility, setColumnVisibility] = useState<VisibilityState>({
    taskCapabilityCost: false,
    upfrontPricingAdjustment: false,
    manual: false,
  })

  const table = useReactTable({
    data,
    columns,
    onSortingChange: setSorting,
    onColumnFiltersChange: setColumnFilters,
    onColumnVisibilityChange: setColumnVisibility,
    getCoreRowModel: getCoreRowModel(),
    getPaginationRowModel: getPaginationRowModel(),
    getSortedRowModel: getSortedRowModel(),
    getFilteredRowModel: getFilteredRowModel(),
    state: {
      sorting,
      columnFilters,
      columnVisibility,
    },
  })

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <div className="flex flex-1 items-center space-x-2">
          <DropdownMenu>
            <DropdownMenuTrigger asChild>
              <Button variant="outline" size="sm" className="ml-auto">
                <SlidersHorizontal className="mr-2 h-4 w-4" />
                View
              </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent align="end" className="w-[200px]">
              <DropdownMenuLabel>Toggle columns</DropdownMenuLabel>
              <DropdownMenuSeparator />
              {table
                .getAllColumns()
                .filter((column) => column.getCanHide())
                .map((column) => {
                  return (
                    <DropdownMenuCheckboxItem
                      key={column.id}
                      className="capitalize"
                      checked={column.getIsVisible()}
                      onCheckedChange={(value) => column.toggleVisibility(!!value)}
                    >
                      {column.id}
                    </DropdownMenuCheckboxItem>
                  )
                })}
            </DropdownMenuContent>
          </DropdownMenu>
        </div>
      </div>
      <div className="rounded-md border">
        <Table>
          <TableHeader>
            {table.getHeaderGroups().map((headerGroup) => (
              <TableRow key={headerGroup.id}>
                {headerGroup.headers.map((header) => {
                  return (
                    <TableHead key={header.id}>
                      {header.isPlaceholder ? null : flexRender(header.column.columnDef.header, header.getContext())}
                    </TableHead>
                  )
                })}
              </TableRow>
            ))}
          </TableHeader>
          <TableBody>
            {table.getRowModel().rows?.length ? (
              table.getRowModel().rows.map((row) => (
                <TableRow key={row.id} data-state={row.getIsSelected() && "selected"}>
                  {row.getVisibleCells().map((cell) => (
                    <TableCell key={cell.id}>{flexRender(cell.column.columnDef.cell, cell.getContext())}</TableCell>
                  ))}
                </TableRow>
              ))
            ) : (
              <TableRow>
                <TableCell colSpan={columns.length} className="h-24 text-center">
                  No results.
                </TableCell>
              </TableRow>
            )}
          </TableBody>
        </Table>
      </div>
      <div className="flex items-center justify-end space-x-2">
        <Button variant="outline" size="sm" onClick={() => table.previousPage()} disabled={!table.getCanPreviousPage()}>
          Previous
        </Button>
        <Button variant="outline" size="sm" onClick={() => table.nextPage()} disabled={!table.getCanNextPage()}>
          Next
        </Button>
      </div>
    </div>
  )
}

