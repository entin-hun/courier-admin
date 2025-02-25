#!/bin/bash

# Configuration
LOG_FILE="/var/log/courier-sync.log"
LOCK_FILE="/tmp/courier-sync.lock"
DB_NAME="courier_admin"
DB_USER="courier_admin"

# Function to log messages
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Check if script is already running
if [ -f "$LOCK_FILE" ]; then
    log "Script is already running. Exiting."
    exit 1
fi

# Create lock file
touch "$LOCK_FILE"

# Cleanup function
cleanup() {
    rm -f "$LOCK_FILE"
    log "Script finished"
}

# Set cleanup to run on script exit
trap cleanup EXIT

# Get access token
get_access_token() {
    local response
    response=$(curl -s 'https://authentication.wolt.com/v1/wauth2/access_token' \
        -H 'content-type: application/x-www-form-urlencoded' \
        --data-raw "grant_type=refresh_token&refresh_token=$WOLT_REFRESH_TOKEN")
    
    # Check if response contains access_token
    if echo "$response" | grep -q "access_token"; then
        # Store new tokens in database
        echo "$response" | jq -r '.access_token' | psql -d "$DB_NAME" -U "$DB_USER" -c \
            "INSERT INTO tokens (access_token, refresh_token, expires_at) 
             VALUES ('$(echo "$response" | jq -r '.access_token')', 
                     '$(echo "$response" | jq -r '.refresh_token')', 
                     NOW() + INTERVAL '30 minutes');"
        
        echo "$response" | jq -r '.access_token'
    else
        log "Failed to get access token: $response"
        exit 1
    fi
}

# Get date range for API calls
if [ "$(date +%H)" -eq 6 ]; then
    # First run of the day - get yesterday's data
    FROM_DATE=$(date -d "yesterday" +%Y-%m-%d)T00:00:00Z
    TO_DATE=$(date -d "yesterday" +%Y-%m-%d)T23:59:59Z
else
    # Continuous run - get today's data
    FROM_DATE=$(date +%Y-%m-%d)T00:00:00Z
    TO_DATE=$(date +%Y-%m-%d)T23:59:59Z
fi

# Get access token
ACCESS_TOKEN=$(get_access_token)

# Sync couriers
log "Syncing couriers..."
curl -s "https://fleet-management.wolt.com/companies/a9f4f268-7112-4572-bebd-473df4a1c2c4/couriers" \
    -H "authorization: Bearer $ACCESS_TOKEN" | \
    jq -c '.[]' | while read -r courier; do
        psql -d "$DB_NAME" -U "$DB_USER" -c \
            "INSERT INTO couriers (id, first_name, last_name, email, phone, contract_type, vehicle_type) 
             VALUES (
                $(echo "$courier" | jq '.id'), 
                '$(echo "$courier" | jq -r '.firstName')', 
                '$(echo "$courier" | jq -r '.lastName')', 
                '$(echo "$courier" | jq -r '.email')', 
                '$(echo "$courier" | jq -r '.phone')', 
                '$(echo "$courier" | jq -r '.contractType')', 
                '$(echo "$courier" | jq -r '.vehicleType')'
             )
             ON CONFLICT (id) DO UPDATE SET 
                first_name = EXCLUDED.first_name,
                last_name = EXCLUDED.last_name,
                email = EXCLUDED.email,
                phone = EXCLUDED.phone,
                contract_type = EXCLUDED.contract_type,
                vehicle_type = EXCLUDED.vehicle_type,
                updated_at = CURRENT_TIMESTAMP;"
done

# Sync metrics
log "Syncing metrics..."
curl -s "https://delivery-os-metrics.wolt.com/companies/a9f4f268-7112-4572-bebd-473df4a1c2c4/metrics/v2?from=$FROM_DATE&to=$TO_DATE" \
    -H "authorization: Bearer $ACCESS_TOKEN" | \
    jq -c '.[]' | while read -r metric; do
        psql -d "$DB_NAME" -U "$DB_USER" -c \
            "INSERT INTO metrics (
                courier_id, date, 
                tar, tar_updated_at,
                tcr, tcr_updated_at,
                dph, dph_updated_at,
                num_deliveries, deliveries_updated_at,
                online_hours, online_hours_updated_at,
                on_task_hours, on_task_hours_updated_at,
                idle_hours, idle_hours_updated_at,
                tar_shown_tasks, shown_tasks_updated_at,
                tar_started_tasks, started_tasks_updated_at
            ) 
            VALUES (
                $(echo "$metric" | jq '.courierId'),
                '$(echo "$FROM_DATE" | cut -d'T' -f1)',
                $(echo "$metric" | jq '.tar.value // 0'),
                '$(echo "$metric" | jq -r '.tar.updatedAt // "null"')',
                $(echo "$metric" | jq '.tcr.value // 0'),
                '$(echo "$metric" | jq -r '.tcr.updatedAt // "null"')',
                $(echo "$metric" | jq '.dph.value // 0'),
                '$(echo "$metric" | jq -r '.dph.updatedAt // "null"')',
                $(echo "$metric" | jq '.numDeliveries.value // 0'),
                '$(echo "$metric" | jq -r '.numDeliveries.updatedAt // "null"')',
                $(echo "$metric" | jq '.onlineHours.value // 0'),
                '$(echo "$metric" | jq -r '.onlineHours.updatedAt // "null"')',
                $(echo "$metric" | jq '.onTaskHours.value // 0'),
                '$(echo "$metric" | jq -r '.onTaskHours.updatedAt // "null"')',
                $(echo "$metric" | jq '.idleHours.value // 0'),
                '$(echo "$metric" | jq -r '.idleHours.updatedAt // "null"')',
                $(echo "$metric" | jq '.tarShownTasks.value // 0'),
                '$(echo "$metric" | jq -r '.tarShownTasks.updatedAt // "null"')',
                $(echo "$metric" | jq '.tarStartedTasks.value // 0'),
                '$(echo "$metric" | jq -r '.tarStartedTasks.updatedAt // "null"')'
            )
            ON CONFLICT (courier_id, date) DO UPDATE SET
                tar = EXCLUDED.tar,
                tar_updated_at = EXCLUDED.tar_updated_at,
                tcr = EXCLUDED.tcr,
                tcr_updated_at = EXCLUDED.tcr_updated_at,
                dph = EXCLUDED.dph,
                dph_updated_at = EXCLUDED.dph_updated_at,
                num_deliveries = EXCLUDED.num_deliveries,
                deliveries_updated_at = EXCLUDED.deliveries_updated_at,
                online_hours = EXCLUDED.online_hours,
                online_hours_updated_at = EXCLUDED.online_hours_updated_at,
                on_task_hours = EXCLUDED.on_task_hours,
                on_task_hours_updated_at = EXCLUDED.on_task_hours_updated_at,
                idle_hours = EXCLUDED.idle_hours,
                idle_hours_updated_at = EXCLUDED.idle_hours_updated_at,
                tar_shown_tasks = EXCLUDED.tar_shown_tasks,
                shown_tasks_updated_at = EXCLUDED.shown_tasks_updated_at,
                tar_started_tasks = EXCLUDED.tar_started_tasks,
                started_tasks_updated_at = EXCLUDED.started_tasks_updated_at;"
done

# Sync earnings
log "Syncing earnings..."
curl -s "https://delivery-os-earnings.wolt.com/companies/a9f4f268-7112-4572-bebd-473df4a1c2c4/earnings?from=$FROM_DATE&to=$TO_DATE" \
    -H "authorization: Bearer $ACCESS_TOKEN" | \
    jq -c '.[]' | while read -r earning; do
        psql -d "$DB_NAME" -U "$DB_USER" -c \
            "INSERT INTO earnings (
                courier_id, date,
                task_distance_cost,
                shift_guarantee,
                upfront_pricing_adjustment,
                task_pickup_distance_cost,
                task_base_cost,
                tip,
                task_capability_cost,
                manual_adjustment
            )
            VALUES (
                $(echo "$earning" | jq '.courierId'),
                '$(echo "$FROM_DATE" | cut -d'T' -f1)',
                $(echo "$earning" | jq '.taskDistanceCost // 0'),
                $(echo "$earning" | jq '.shiftGuarantee // 0'),
                $(echo "$earning" | jq '.upfrontPricingAdjustment // 0'),
                $(echo "$earning" | jq '.taskPickupDistanceCost // 0'),
                $(echo "$earning" | jq '.taskBaseCost // 0'),
                $(echo "$earning" | jq '.tip // 0'),
                $(echo "$earning" | jq '.taskCapabilityCost // 0'),
                $(echo "$earning" | jq '.manual // 0')
            )
            ON CONFLICT (courier_id, date) DO UPDATE SET
                task_distance_cost = EXCLUDED.task_distance_cost,
                shift_guarantee = EXCLUDED.shift_guarantee,
                upfront_pricing_adjustment = EXCLUDED.upfront_pricing_adjustment,
                task_pickup_distance_cost = EXCLUDED.task_pickup_distance_cost,
                task_base_cost = EXCLUDED.task_base_cost,
                tip = EXCLUDED.tip,
                task_capability_cost = EXCLUDED.task_capability_cost,
                manual_adjustment = EXCLUDED.manual_adjustment,
                updated_at = CURRENT_TIMESTAMP;"
done

# Sync cash balances
log "Syncing cash balances..."
curl -s "https://delivery-os-metrics.wolt.com/companies/a9f4f268-7112-4572-bebd-473df4a1c2c4/cash-balances" \
    -H "authorization: Bearer $ACCESS_TOKEN" | \
    jq -c '.[]' | while read -r balance; do
        psql -d "$DB_NAME" -U "$DB_USER" -c \
            "INSERT INTO cash_balances (
                courier_id,
                amount,
                currency_code,
                updated_at
            )
            VALUES (
                $(echo "$balance" | jq '.courierId'),
                $(echo "$balance" | jq '.amount'),
                '$(echo "$balance" | jq -r '.currencyCode')',
                '$(echo "$balance" | jq -r '.updatedAt')'
            );"
done

# Sync with Coda
log "Syncing with Coda..."
psql -d "$DB_NAME" -U "$DB_USER" -t -A -F"," -c \
    "SELECT id, first_name, last_name FROM couriers WHERE id NOT IN (
        SELECT DISTINCT courier_id FROM coda_synced_couriers
    );" | while IFS=, read -r id first_name last_name; do
    curl -s -H "Authorization: Bearer $CODA_API_TOKEN" \
         -X POST -H "Content-Type: application/json" \
         -d "{\"rows\": [{\"cells\": [{\"column\": \"id\", \"value\": \"$id\"}]}]}" \
         "https://coda.io/apis/v1/docs/nj9gkogd55/tables/grid-TIX0wVrejQ/rows"
    
    # Mark as synced
    psql -d "$DB_NAME" -U "$DB_USER" -c \
        "INSERT INTO coda_synced_couriers (courier_id) VALUES ($id);"
done

log "Sync completed successfully"