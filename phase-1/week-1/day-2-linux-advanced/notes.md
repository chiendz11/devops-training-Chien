1. Sự khác nhau giữa SIGTERM, SIGKILL, SIGHUP, SIGINT?
- SIGTERM là signal yêu cầu process dừng, có nghĩa là process đó có thể thực hiện nốt các tasks đang dang dở nếu chúng có code handler SIGTERM. Nếu không có thì process đó sẽ bị kill luôn, không được thực hiện nốt các tasks đang dở. Hoặc có SIGTERM có timeout để process không làm nốt tasks quá lâu

- SIGKILL là signal kill ngay process, không được thực hiện nốt các tasks đang dở, và cũng process dù có code handler cũng không bắt được

- SIGHUP là signal báo cho process rằng terminal/session điều khiển nó đã bị “hang up” / mất kết nối. Mặc định process bị terminate, với nhiều daemon/server, SIGHUP thường được dùng theo quy ước để reload config mà không cần restart hẳn process
- SIGINT là signal từ user chủ động bấm CTRL + C để yêu cầu ngắt tasks đang chạy hiện tại của process foreground(nó cho process biết hành động từ user gửi signal), hành vi mặc định sau khi process nhận SIGINT là terminate(không làm được thêm tasks gì). Có thể dùng code handler để chạy cleanup, in summary,.. rồi mới terminate hoặc là ignore và chạy tiếp

2. nohup vs disown vs setsid khác nhau thế nào?
- nohup = no hangup là lệnh giúp process foreground bỏ qua signal SIGHUP ngay từ đầu, nên khi terminal/ssh bị đóng, nó không bị terminated(hành động default) vì SIGHUP và stdout của nó sẽ được ghi vào nohup.out

- disowm(của shell) là lệnh giúp process(job) đang chạy background trên shell tách ra khỏi shell(job table). Nếu terminal đóng và shell thoát, shell sẽ không gửi SIGHUP đến process nữa do process đã detach khỏi shell(job table) => process vẫn chạy nhưng trở thành orphan process và được systemd nhận nuôi. Và process có ghi output thì sẽ gặp lỗi vì chỗ để in output đã mất, vậy nên cần chỉ định nơi để in output bằng redirect

- setsid là lệnh giúp process chạy trong session mới, tách nó ra khỏi terminal/session hiện tại(xử lý session / controlling terminal ở tầng kernel) => process có SID mới, thường PGID mới, và không còn controlling TTY hiện tại( tức nó không còn bị terminal cũ điều khiển theo kiểu: Ctrl+C  → SIGINT, ...;terminal đóng / SSH ngắt → SIGHUP )

3. Khi nào dùng pkill -f?
- Gửi signal tới các process có full command line match với <pattern>.
- Khi muốn kill process theo đường dẫn hoặc config riêng, nghĩa là nếu có nhiều process có cùng name, nhưng chỉ muốn kill process có path và config riêng?

4.
- STAT là trạn thái hiện tại của process:
+ R = running/runnable: process đã ready hoặc đang running trong cpu
+ S = sleeping: process nằm trong wait queue
+ D = uninterruptible sleep: process đang ngủ nhưng ở trạng thái khó ngắt, thường là đang chờ I/O cấp kernel.p
+ Z = zombie: process đã chết rồi, nhưng parent chưa wait() để thu dọn exit status
+ T = Stopped / Traced: process đã dừng
+ Trong STAT, chữ đầu là quan trọng nhất. Các ký tự sau là thông tin bổ sung:
s   session leader
l   multi-threaded process
+   foreground process group của terminal
<   priority cao
N   priority thấp / nice

5. Zombie process là gì, làm sao nhận diện?
- là process đã chạy xong và đã chết, nhưng vẫn còn một entry trong process table vì parent process chưa gọi wait() / waitpid() để “thu xác” nó
- dấu hiệu chính là STAT = Z và CMD có <defunct>, dùng lệnh ps -eo pid,ppid,stat,cmd | awk 'NR==1 || $3 ~ /Z/' hoặc ps -e | grep '[d]efunct'
