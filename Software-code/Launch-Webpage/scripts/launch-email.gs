/**
 * Slipstream Launch Email Script
 * 
 * This Google Apps Script sends launch emails to waitlist subscribers.
 * It tracks which emails have been sent to prevent duplicates.
 * 
 * SETUP INSTRUCTIONS:
 * 1. Open your Google Sheet with waitlist data
 * 2. Go to Extensions > Apps Script
 * 3. Delete any existing code and paste this script
 * 4. Update SHEET_NAME if your sheet has a different name
 * 5. Update EVENT_CONFIG with your actual event details
 * 6. Save the script (Ctrl/Cmd + S)
 * 7. Run sendLaunchEmails() function manually or set up a trigger
 * 
 * SHEET REQUIREMENTS:
 * - Column A: Name (optional, will use "there" if empty)
 * - Column B: Email (required)
 * - Column C: Recommendation (not used in this script)
 * - Column D: LaunchEmailSentAt (auto-populated by this script)
 */

// Configuration
const SHEET_NAME = "Slipstream-waitlist"; // Change this to match your sheet name
const EVENT_CONFIG = {
  location: "Concordia University",
  address: "1455 De Maisonneuve Blvd. W, Montreal, QC",
  date: "April 2025", // Update with actual date
  time: "between 10 AM and 4 PM",
};

/**
 * Main function to send launch emails
 * Run this function manually or set up a time-based trigger
 */
function sendLaunchEmails() {
  const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName(SHEET_NAME);
  
  if (!sheet) {
    Logger.log(`ERROR: Sheet "${SHEET_NAME}" not found. Please update SHEET_NAME constant.`);
    return;
  }
  
  const data = sheet.getDataRange().getValues();
  const headers = data[0];
  
  // Find column indices
  const nameCol = headers.indexOf("Name");
  const emailCol = headers.indexOf("Email");
  const sentAtCol = headers.indexOf("LaunchEmailSentAt");
  
  if (emailCol === -1) {
    Logger.log("ERROR: 'Email' column not found in sheet.");
    return;
  }
  
  if (sentAtCol === -1) {
    Logger.log("ERROR: 'LaunchEmailSentAt' column not found. Please add this column to track sent emails.");
    return;
  }
  
  let sentCount = 0;
  let skippedCount = 0;
  let errorCount = 0;
  
  // Start from row 2 (skip header)
  for (let i = 1; i < data.length; i++) {
    const row = data[i];
    const name = nameCol !== -1 ? row[nameCol] : "";
    const email = row[emailCol];
    const sentAt = row[sentAtCol];
    
    // Skip if no email
    if (!email || email.trim() === "") {
      Logger.log(`Row ${i + 1}: Skipping - no email address`);
      skippedCount++;
      continue;
    }
    
    // Skip if already sent
    if (sentAt && sentAt !== "") {
      Logger.log(`Row ${i + 1}: Skipping ${email} - already sent on ${sentAt}`);
      skippedCount++;
      continue;
    }
    
    // Send email
    try {
      sendLaunchEmail(name, email);
      
      // Mark as sent with timestamp
      const timestamp = new Date().toISOString();
      sheet.getRange(i + 1, sentAtCol + 1).setValue(timestamp);
      
      Logger.log(`Row ${i + 1}: ✓ Sent to ${email}`);
      sentCount++;
      
      // Add small delay to avoid rate limiting (optional)
      Utilities.sleep(500);
      
    } catch (error) {
      Logger.log(`Row ${i + 1}: ERROR sending to ${email}: ${error.message}`);
      errorCount++;
    }
  }
  
  // Summary
  Logger.log("\n=== EMAIL SEND SUMMARY ===");
  Logger.log(`Sent: ${sentCount}`);
  Logger.log(`Skipped: ${skippedCount}`);
  Logger.log(`Errors: ${errorCount}`);
  Logger.log(`Total rows processed: ${data.length - 1}`);
}

/**
 * Sends a single launch email
 * @param {string} name - Recipient name (can be empty)
 * @param {string} email - Recipient email address
 */
function sendLaunchEmail(name, email) {
  const greeting = name && name.trim() !== "" ? `Hi ${name},` : "Hi there,";
  
  const subject = "<b>Slipstream is Live</b>";

  const body = 
    `${greeting}<br><br>` +
    `Slipstream is officially going live and as an early supporter, you're invited.<br><br>` +
    `<b>Where:</b> ${EVENT_CONFIG.location}, ${EVENT_CONFIG.address}<br>` +
    `<b>When:</b> ${EVENT_CONFIG.date}<br>` +
    `<b>Time:</b> ${EVENT_CONFIG.time}<br><br>` +
    `Come try the simulator, meet the crew, and hang out with other drivers.<br><br>` +
    `More details + RSVP link soon.<br><br>` +
    `See you on track,<br>` +
    `The Slipstream Team` +

    `
    <br><br>
    <hr style="border:none;border-top:1px solid #444;">
    <div style="text-align:center;font-size:12px;color:#666;">
      
      <img src="https://slipstream-3gw.pages.dev/logo-slipstream.png" 
          alt="Slipstream Logo"
          width="140"
          style="margin-bottom:10px;">
      
      <br>

      <a href="https://www.instagram.com/slipstrearn" 
        style="margin-right:12px;color:#e63946;text-decoration:none;font-weight:bold;">
        Instagram
      </a>

      <a href="https://www.youtube.com/channel/UCHCf9AAipaBe-YrR8mLdMkw" 
        style="color:#e63946;text-decoration:none;font-weight:bold;">
        YouTube
      </a>

      <br><br>
      © Slipstream 2025 — Montreal, QC
    </div>`;

  GmailApp.sendEmail(email, subject.replace(/<[^>]*>?/gm, ''), "", { htmlBody: body });
}

/**
 * Test function - sends email to yourself only
 * Use this to test the email format before sending to everyone
 */
function testLaunchEmail() {
  const testEmail = Session.getActiveUser().getEmail();
  const testName = "Test User";
  
  Logger.log(`Sending test email to: ${testEmail}`);
  
  try {
    sendLaunchEmail(testName, testEmail);
    Logger.log("✓ Test email sent successfully!");
    Logger.log("Check your inbox and verify the email looks correct.");
  } catch (error) {
    Logger.log(`ERROR: ${error.message}`);
  }
}

/**
 * Helper function to add LaunchEmailSentAt column if it doesn't exist
 * Run this once if you need to add the tracking column
 */
function addTrackingColumn() {
  const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName(SHEET_NAME);
  
  if (!sheet) {
    Logger.log(`ERROR: Sheet "${SHEET_NAME}" not found.`);
    return;
  }
  
  const headers = sheet.getRange(1, 1, 1, sheet.getLastColumn()).getValues()[0];
  
  if (headers.indexOf("LaunchEmailSentAt") === -1) {
    const lastCol = sheet.getLastColumn();
    sheet.getRange(1, lastCol + 1).setValue("LaunchEmailSentAt");
    Logger.log("✓ Added 'LaunchEmailSentAt' column");
  } else {
    Logger.log("'LaunchEmailSentAt' column already exists");
  }
}
