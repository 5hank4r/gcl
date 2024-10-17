# GitHub Calendar Access Checker

In today’s digital landscape, it's easy for users to accidentally expose their Google Calendar to the public. This can lead to sensitive information, such as private meetings, event details, and attendee lists, being accessible to unauthorized individuals. 

Our suite of tools is designed to help security professionals and bug bounty hunters identify these accidental exposures. By checking the accessibility of Google Calendar URLs associated with specific email addresses, our tools can reveal which calendars are publicly accessible. 


## Prerequisites

Before using the tools, ensure you have the following installed:

- **httpx**: [Install here](https://github.com/projectdiscovery/httpx)
- **wget**: Install via your package manager (e.g., `apt`, `brew`)
- **Go**: [Download from here](https://golang.org/dl/)



## Features

- **URL Checking:**  
  This feature allows users to validate the accessibility of Google Calendar URLs based on specific email addresses. By ensuring that the URLs are reachable, you can confirm whether a target's calendar is exposed, providing critical insight for potential vulnerabilities.

- **File Downloading:**  
  With this tool, you can seamlessly download `.ics` files from the URLs that have been deemed accessible. This functionality is vital for gathering calendar data, as `.ics` files contain event information that can be pivotal in understanding a target's schedule and potential weaknesses.

- **Data Analysis:**  
  After downloading the relevant files, our tool enables you to run a Go script that analyzes the content for sensitive information. This analysis can uncover private events, attendee lists, and other confidential details that may have been inadvertently shared, highlighting potential security risks.




## Usage

To use the automation script, run:

``
./autoRun.sh -f <email_file> -o
``

![alt text](image.png)

![alt text](image-1.png)

![alt text](image-2.png)

