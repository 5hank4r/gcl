package main

import (
    "bufio"
    "flag"
    "fmt"
    "os"
    "regexp"
    "strings"
    "sync"
)

const (
    colorReset  = "\033[0m"
    colorRed    = "\033[31m"
    colorGreen  = "\033[32m"
)

func searchInFiles(directory string, wg *sync.WaitGroup) {
    defer wg.Done()

    files, err := os.ReadDir(directory)
    if err != nil {
        fmt.Printf("%sError reading directory: %s%s\n", colorRed, directory, colorReset)
        return
    }

    for _, file := range files {
        if !file.IsDir() {
            fileName := fmt.Sprintf("%s/%s", directory, file.Name())
            f, err := os.Open(fileName)
            if err != nil {
                fmt.Printf("%sError opening file: %s%s\n", colorRed, fileName, colorReset)
                continue
            }
            defer f.Close()

            scanner := bufio.NewScanner(f)
            allBusy := true
            hasSensitiveInfo := false
            busyPattern := regexp.MustCompile(`SUMMARY:.*\bBusy\b`) // Regex to find exact word "Busy"
            sensitivePattern := regexp.MustCompile(`SUMMARY:.*\bBusy\b|SUMMARY:.*\bBusy\w*\b`) // Regex to find "Busy" or "Busy" followed by other characters

            for scanner.Scan() {
                line := scanner.Text()
                if strings.HasPrefix(line, "SUMMARY:") {
                    if busyPattern.MatchString(line) {
                        // If line contains exact "Busy", continue checking
                        continue
                    } else if sensitivePattern.MatchString(line) {
                        // If line contains "Busy" as part of a larger word, mark as sensitive
                        hasSensitiveInfo = true
                        break
                    } else {
                        allBusy = false
                    }
                }
            }

            if hasSensitiveInfo {
                fmt.Printf("%s%s contains sensitive information!%s\n", colorRed, fileName, colorReset)
            } else if allBusy {
                fmt.Printf("%s%s contains non-sensitive information.%s\n", colorGreen, fileName, colorReset)
            } else {
                fmt.Printf("%s%s contains mixed information.%s\n", colorRed, fileName, colorReset)
            }

            if err := scanner.Err(); err != nil {
                fmt.Println("Error reading file:", err)
            }
        }
    }
}

func main() {
    dir := flag.String("dir", "", "Directory with downloaded files")
    flag.Parse()

    if *dir == "" {
        fmt.Println("Please provide the directory with downloaded files using the -dir flag.")
        return
    }

    var wg sync.WaitGroup
    wg.Add(1)
    go searchInFiles(*dir, &wg)
    wg.Wait()
}