-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Tokens table for managing authentication
CREATE TABLE tokens (
    id uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
    access_token TEXT NOT NULL,
    refresh_token TEXT NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Couriers table
CREATE TABLE couriers (
    id INTEGER PRIMARY KEY,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    email TEXT,
    phone TEXT,
    contract_type TEXT,
    vehicle_type TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Metrics table
CREATE TABLE metrics (
    id uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
    courier_id INTEGER REFERENCES couriers(id),
    date DATE NOT NULL,
    tar NUMERIC,
    tar_updated_at TIMESTAMP WITH TIME ZONE,
    tcr NUMERIC,
    tcr_updated_at TIMESTAMP WITH TIME ZONE,
    dph NUMERIC,
    dph_updated_at TIMESTAMP WITH TIME ZONE,
    num_deliveries INTEGER,
    deliveries_updated_at TIMESTAMP WITH TIME ZONE,
    online_hours NUMERIC,
    online_hours_updated_at TIMESTAMP WITH TIME ZONE,
    on_task_hours NUMERIC,
    on_task_hours_updated_at TIMESTAMP WITH TIME ZONE,
    idle_hours NUMERIC,
    idle_hours_updated_at TIMESTAMP WITH TIME ZONE,
    tar_shown_tasks INTEGER,
    shown_tasks_updated_at TIMESTAMP WITH TIME ZONE,
    tar_started_tasks INTEGER,
    started_tasks_updated_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(courier_id, date)
);

-- Earnings table
CREATE TABLE earnings (
    id uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
    courier_id INTEGER REFERENCES couriers(id),
    date DATE NOT NULL,
    task_distance_cost NUMERIC DEFAULT 0,
    shift_guarantee NUMERIC DEFAULT 0,
    upfront_pricing_adjustment NUMERIC DEFAULT 0,
    task_pickup_distance_cost NUMERIC DEFAULT 0,
    task_base_cost NUMERIC DEFAULT 0,
    tip NUMERIC DEFAULT 0,
    task_capability_cost NUMERIC DEFAULT 0,
    manual_adjustment NUMERIC DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(courier_id, date)
);

-- Cash balances table
CREATE TABLE cash_balances (
    id uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
    courier_id INTEGER REFERENCES couriers(id),
    amount NUMERIC NOT NULL,
    currency_code TEXT NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better query performance
CREATE INDEX idx_metrics_courier_date ON metrics(courier_id, date);
CREATE INDEX idx_earnings_courier_date ON earnings(courier_id, date);
CREATE INDEX idx_cash_balances_courier ON cash_balances(courier_id);