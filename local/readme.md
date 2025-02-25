# Create user and set up PostgreSQL
sudo adduser courier-admin
sudo -u postgres createuser courier_admin
sudo -u postgres createdb courier_admin
sudo -u postgres psql -c "ALTER USER courier_admin WITH PASSWORD 'your_secure_password';"

# Install dependencies
sudo apt-get update
sudo apt-get install -y postgresql postgresql-contrib jq curl

# Copy files
sudo cp sync-courier-data.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/sync-courier-data.sh
sudo cp courier-sync.service /etc/systemd/system/
sudo cp courier-sync.timer /etc/systemd/system/

# Initialize database
sudo -u postgres psql courier_admin < init.sql

# Start services
sudo systemctl daemon-reload
sudo systemctl enable courier-sync.timer
sudo systemctl start courier-sync.timer
