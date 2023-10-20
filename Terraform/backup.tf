#Yandex Backup
  resource "yandex_compute_snapshot_schedule" "backup" {
   name = "my7day"

   schedule_policy {
     expression = "0 0 * * *"
   }

   snapshot_count = 7

   disk_ids = [
      for server in yandex_compute_instance.vm : server.boot_disk.0.disk_id
   ]
 }