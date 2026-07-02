1. Liệt kê 5 process tốn RAM nhất, cột PID + COMMAND + %MEM:
ps -e -o pid,comm,%mem --sort=-%mem | head -6

2. Đếm số file .log trong /var/log (không đi sâu hơn 2 cấp).
find /var/log -maxdepth 2 -type f -name "*.log" | wc -l

3. Tìm 10 IP xuất hiện nhiều nhất trong /var/log/auth.log (nếu có):
grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' /var/log/auth.log | sort | uniq -c | sort -nr | head -10

4. Lấy hostname + kernel version + uptime, ghi vào system-info.txt theo format:
host=<hostname>
kernel=<version>
uptime=<thời gian>
{
echo "host=$(uname -n)" > system-info.txt
echo "kernel=$(uname -r)" >> system-info.txt
echo "uptime=$(uptime)" >> system-info.txt
}