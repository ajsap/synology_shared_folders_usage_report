# Synology Shared Folders Usage Report

Welcome to the **Synology Shared Folders Usage Report** script! This tool is designed to help you monitor and report the disk usage of shared folders on your Synology NAS, supporting both single and multiple volumes. It's ideal for administrators who need a clear overview of storage utilisation across their network-attached storage systems.

## Features

- **Supports Single and Multiple Volumes**: Choose between versions for single volume (v1.0) or multiple volumes (v2.0) based on your needs.
- **Detailed Reporting**: Provides per-folder and per-volume usage statistics with clear subtotals and grand totals.
- **System Statistics**: Includes vital system information such as uptime, memory usage, CPU load, and the top processes by CPU usage.
- **Customisable**: Exclude specific folders or directories from the report as needed.
- **Optimised Performance**: Designed to run efficiently, even on systems with large amounts of data.
- **Easy Integration**: Can be scheduled using Synology's Task Scheduler for automated reporting.

## Getting Started

### Prerequisites

- Tested on a Synology NAS running DSM version 7.2.2.
- Basic knowledge of command-line operations.
- User account with sufficient permissions to execute scripts and access shared folders.
- Set up Synology Email notifications from the DSM Control Panel -> Notification -> Email -> Sender.

### Installation

1. **Create a Dedicated Scripts Folder**

   It is recommended to have a dedicated shared folder for scripts, for example, `Scripts`.

2. **Copy the Script to the Shared Folder**

   Copy one of the `.sh` files (depending on your requirements—the single or multiple version) to the shared folder you created.

3. **Create a Scheduled Task in DSM**

   - Navigate to DSM **Control Panel** -> **Task Scheduler**.
   - Click on **Create** and select **Scheduled Task** > **User-defined script**.

4. **Configure the Task**

   - **General Settings**:
     - **Task Name**: `shared_folder_usage_report`
     - **User**: Select `root` from the dropdown menu.

   - **Schedule Settings**:
     - Set the task to run **Monthly**.
     - In the **Run on the following days** section, select **Last** and ensure all days are ticked. This will schedule the script to run at the end of each month, regardless of the specific day.

   - **Task Settings**:
     - **User-defined script**:
       ```bash
       bash /volume1/Scripts/shared_folder_usage_report.sh
       ```
       *(Adjust the path to the script if necessary.)*

   - **Notification Settings**:
     - Under **Notification**, tick **Send run details by email**.
     - Enter your email address to receive the report via email.

5. **Test the Script Manually**

   - Before relying on the scheduled task, it's advisable to test the script manually.
   - Open **Terminal** or **SSH** into your Synology NAS.
   - Run the script:
     ```bash
     bash /volume1/Scripts/shared_folder_usage_report.sh
     ```
     *(Adjust the path if necessary.)*
   - Verify that the output meets your expectations.

6. **Finalise the Scheduled Task**

   - If the manual test is successful, your scheduled task is set up correctly.
   - The script will now run automatically at the end of each month and send the report to your email.

---

By following these steps, you'll have the **Synology Shared Folders Usage Report** script up and running, providing you with valuable insights into your NAS storage utilisation.
