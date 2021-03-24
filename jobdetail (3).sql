const puppeteer = require("puppeteer");
const dbConn = require("../config/connect");
const publicIp = require("public-ip");
let geoip = require("geoip-lite");
const moment = require("moment");

process.env.TZ = "America/Chicago";
moment.tz.setDefault("America/Chicago");

var globalVariableForHoldingPageData = "";
var globalPageInstance;
var globalBrowserInstance;
var isMicrotypeExcecutedSucceessfully = true;

function getRandomArbitraryNumber(min, max, isdecimal = false) {
  let result = 0;
  if (isdecimal === true) {
    var randomnum = (Math.random() * (max - min) + min).toFixed(2) * 1;
    return randomnum;
  }
  result = Math.floor(Math.random() * (max - min) + min);
  return result;
}

async function insertDataInDBForNotFoundEvent(jobLogObject, macroIDMessage) {
  isMicrotypeExcecutedSucceessfully = false
  jobLogObject.logStatus = "Error";
  (jobLogObject.logAction = "Done"),
    (jobLogObject.techMsg = `500:${macroIDMessage}`),
    (jobLogObject.displayMsg = `500:${macroIDMessage}`);

  let formattedTime = new Date(new Date())
    .toISOString()
    .toString()
    .replace("Z", "")
    .replace("T", " ")
    .split(".")[0];
  jobLogObject.endDateTime = formattedTime;

  let ipOfLocalMachine = await publicIp.v4();

  var { country, region, timezone, city } = await geoip.lookup(
    ipOfLocalMachine
  );

  jobLogObject.payload = `${ipOfLocalMachine} | ${city} | ${country} | ${region}`;

  let insertResult = await insertDataInJobLog(jobLogObject);

  if (insertResult) {
    console.log(`data for ${macroIDMessage} inserted successfully !`);
  } else {
    console.log(`DB call failed ! for ${macroIDMessage}`);
  }
}

function insertDataInDBForSuccess(jobLogObject, macroIDMessage) {
  return new Promise(async (resolveWithSuccess, rejectWitherror) => {
    jobLogObject.logStatus = "Approved";
    (jobLogObject.logAction = "Done"),
      (jobLogObject.techMsg = `${jobLogObject.jobID}`),
      (jobLogObject.displayMsg = `200 : Done`);

    let formattedTime = new Date(new Date())
      .toISOString()
      .toString()
      .replace("Z", "")
      .replace("T", " ")
      .split(".")[0];
    jobLogObject.endDateTime = formattedTime;

    let ipOfLocalMachine = await publicIp.v4();

    var { country, region, timezone, city } = await geoip.lookup(
      ipOfLocalMachine
    );

    jobLogObject.payload = `${ipOfLocalMachine} | ${city} | ${country} | ${region}`;

    insertDataInJobLog(jobLogObject)
      .then((data) => {
        resolveWithSuccess(true);
      })
      .catch((error) => {
        console.log("error is ", JSON.stringify(error, null, 4));
        rejectWitherror(false);
      });
  });
}

async function fetchDataFromJobDetail(jobID) {
  //This function will return all the jobs according to their macroOrder
  return new Promise((resolve, reject) => {
    try {
      dbConn.query(
        `select * from jobdetail where jobID = '${jobID}' order by macroOrder`,
        function (err, data, fields) {
          if (err) {
            console.log("error in finding job details ", err.message);
            reject(false);
          }
          if (data) {
            if (data.length > 0) {
              resolve(data);
            }
          }
        }
      );
    } catch (error) {
      console.log("error in while fetching jobs", error.message);
    }
  });
}

//Insert data in job log
function insertDataInJobLog(jobDetails) {
  return new Promise((resolve, reject) => {
    dbConn.query(`insert into joblog SET ?`, jobDetails, function (err, data) {
      if (err) {
        console.log("error while inserting in the  ", err.stack);
        reject(false);
      }
      resolve(data);
      console.log("data insertDataInJobLog is ", data);
    });
  });
}

function trimLinks(arrayOfLinks) {
  if (arrayOfLinks) {
    return new Promise((resolve, reject) => {
      for (var i = 0; i < arrayOfLinks.length; i++) {
        arrayOfLinks[i] = arrayOfLinks[i].replace(/(\r\n|\n|\r)/gm, "").trim();
      }
      return resolve(arrayOfLinks);
    });
  }
}

async function executeMacroTypeSearchEngine(
  typeTime,
  clickTime,
  element,
  jobLogObject
) {
  try {
    let {
      jobID,
      macroType,
      searchEngine,
      searchTermName,
      linkOrTitle,
      pageVerifyText,
    } = element;

    console.log(
      "------- macrotype deaitails are ",
      JSON.stringify(element, null, 4)
    );

    const browser = await puppeteer.launch({
      headless: false,
      executablePath: "/usr/bin/chromium-browser",
      ignoreDefaultArgs: ["--enable-automation"],
    });

    globalBrowserInstance = browser;

    const page = await browser.newPage();

    await page.goto("https://www.google.com");

    await page.keyboard.type(searchTermName, {
      delay: typeTime + 10,
    });

    await page.keyboard.press("Enter");

    await page.waitForSelector("#search");

    try {
      await page.waitForNavigation({
        waitUntil: "domcontentloaded",
        timeout: 0,
      });
      await sleep(30000);
    } catch (ex) {
      console.log(ex.message);
      await sleep(30000);
    }

    const searchTitles = await page.$$eval("h3", (as) =>
      as.map((a) => a.innerHTML)
    );

    console.log("\n search title are ", JSON.stringify(searchTitles, null, 4));

    const isTitleIsPresesnt = searchTitles.filter(
      (element) => element === linkOrTitle
    );

    if (!isTitleIsPresesnt) {
      console.log("no title provided ");
      return;
    }
    if (isTitleIsPresesnt.length > 0) {
      await page.waitForSelector("h3.LC20lb", {
        timeout: 10000,
      });
      let indexTosearch = searchTitles.indexOf(isTitleIsPresesnt[0]);
      var wait = await page.evaluate((indexTosearch) => {
        return new Promise((resolve, reject) => {
          let elements = document.querySelectorAll("h3");
          //sleep(clickTime)
          elements[indexTosearch].click();
          resolve(elements);
        });
      }, indexTosearch);

      console.log("verifying text");

      try {
        await page.waitForNavigation({
          waitUntil: "load",
          timeout: 1000 * 60,
        });
      } catch (ex) {
        console.log(ex.message);
      }

      console.log("crossed 1st t-c");

      const nextpageData = await page.evaluate(async () => {
        return document.querySelector("*").outerHTML;
      });

      console.log("page verify text is ", pageVerifyText);

      let result = nextpageData.search(pageVerifyText);

      if (result > -1) {
        console.log(" \n verfied text found for first time \n ");
        globalVariableForHoldingPageData = nextpageData;
        globalPageInstance = page;
      } else {
        console.log("\n verfied text not found for first micro type\n ");
        await insertDataInDBForNotFoundEvent(jobLogObject);
      }
    } else {
      console.log("\n title is not found for microtype search engine\n ");
      await insertDataInDBForNotFoundEvent(
        jobLogObject,
        "link or title not found"
      );
    }
  } catch (error) {
    console.log(
      "excepion occured in >>> executeMacroTypeSearchEngine <<< ",
      error.stack
    );
    await insertDataInDBForNotFoundEvent(
      jobLogObject,
      `executeMacroTypeSearchEngine exception  ${error.message}`
    );
  }
}

async function executeMacroTypePageLink(clickTime, typeTime, jobObject) {
  try {
    let {
      jobID,
      macroType,
      searchEngine,
      searchTermName,
      linkOrTitle,
      pageVerifyText,
    } = jobObject;

    if (globalVariableForHoldingPageData === "") {
      //this will check wheather the data is loaded for page link
      console.log("request cannot be processed");
      return;
    }

    if (macroType === "PageLink") {
      console.log(`\n searching page link title ${linkOrTitle}\n`);

      const searchTitles = await globalPageInstance.$$eval("a", (as) =>
        as.map((a) => a.innerHTML)
      );

      let newSearchTitlesForPageLink = await trimLinks(searchTitles);

      console.log(
        "\n search title are ",
        JSON.stringify(newSearchTitlesForPageLink, null, 4)
      );

      const isTitleIsPresesnt = newSearchTitlesForPageLink.filter(
        (element) => element === linkOrTitle
      );

      let data = await setTimeout(() => Promise.resolve(true), 3000);

      if (isTitleIsPresesnt.length > 0) {
        await globalPageInstance.waitForSelector("a", {
          timeout: 10000,
        });

        let indexTosearch = newSearchTitlesForPageLink.indexOf(
          isTitleIsPresesnt[0]
        );

        var wait = await globalPageInstance.evaluate((indexTosearch) => {
          return new Promise((resolve, reject) => {
            let elements = document.querySelectorAll("a");
            //  sleep(clickTime)
            elements[indexTosearch].click();
            resolve(elements);
            // elements[6].click();
          });
        }, indexTosearch);

        try {
          await globalPageInstance.waitForNavigation({
            waitUntil: "domcontentloaded",
            timeout: 0,
          });
          await sleep(30000);
        } catch (ex) {
          console.log(ex.message);
          await sleep(30000);
        }

        const nextpageDataforPageLink = await globalPageInstance.evaluate(
          async () => {
            return document.querySelector("*").outerHTML;
          }
        );

        let verifyPageLinkVerifyText = nextpageDataforPageLink.search(
          pageVerifyText
        );
        if (verifyPageLinkVerifyText > -1) {
          console.log(" \n verfied text found for page link item   \n ");

          globalVariableForHoldingPageData = nextpageDataforPageLink;
        } else {
          console.log("page link verify text not found");
          await insertDataInDBForNotFoundEvent(
            jobLogObject,
            "page link verify text not found"
          );
        }
      } else {
        console.log("search title is not present on the page link page ");
        await insertDataInDBForNotFoundEvent(
          jobLogObject,
          "link or title not found"
        );
      }
    }
  } catch (error) {
    console.log("exception in the >>> executeMacroTypePageLink");
    await insertDataInDBForNotFoundEvent(
      jobLogObject,
      `executeMacroTypePageLink exception  ${error.message}`
    );
  }
}

async function executeMacroTypeDirectPage(
  clickTime,
  typeTime,
  element,
  jobLogObject
) {
  try {
    let {
      jobID,
      macroType,
      searchEngine,
      searchTermName,
      linkOrTitle,
      pageVerifyText,
    } = element;

    if (!globalPageInstance) {
      console.log("not able to open new page");
      return;
    }

    await globalPageInstance.goto(`https://www.${linkOrTitle}`);

    try {
      await globalPageInstance.waitForNavigation({
        waitUntil: "domcontentloaded",
        timeout: 1000 * 60,
      });
    } catch (ex) {
      console.log(ex.message);
    }

    const nextPageDataForDirectPage = await globalPageInstance.evaluate(
      async () => {
        return document.querySelector("*").outerHTML;
      }
    );
    let verifyTextForTheDirectPage = nextPageDataForDirectPage.search(
      pageVerifyText
    );

    if (verifyTextForTheDirectPage > -1) {
      console.log("verified text found for the direct page");
    } else {
      console.log("verified text not found for direct page ");
      await insertDataInDBForNotFoundEvent(
        jobLogObject,
        "verify text not found on the direct page"
      );
    }
  } catch (error) {
    console.log("exception in executeMacroTypeDirectPage    ", error.message);
    await insertDataInDBForNotFoundEvent(
      jobLogObject,
      `DirectPage exception ${error.message}`
    );
  }
}

async function excecuteJob(element) {
  let { id, jobID, runDateTime, scheduleStatus } = element;

  scheduleStatus = "Running";

  try {
    const updateStatus = await updateStatusOfJob(scheduleStatus, id);
    console.log(`Status of job with ID ${jobID} updated to ${status}`);
    s;
  } catch (error) {
    console.log("error while updating");
  }

  let formattedTime = new Date(new Date())
    .toISOString()
    .toString()
    .replace("Z", "")
    .replace("T", " ")
    .split(".")[0];

  let newJobLog = {
    jobID,
    logAction: scheduleStatus,
    startDateTime: formattedTime,
    macroID: id,
  };

  try {
    //All jobs from the job detailes sorted as per the macro order and we are going to iterate
    const allDetailsOfJob = await fetchDataFromJobDetail(jobID);

    //executing the micro types
    for (let i = 0; i < allDetailsOfJob.length; i++) {
      console.log("\n --------------Macro order Started -------------- \n ");
      const element = allDetailsOfJob[i];
      let {
        macroType,
        minCharTime,
        maxCharTime,
        minClickTime,
        maxClickTime,
      } = element;
      console.log(
        `\n --------------Macro order is ${macroType} -------------- \n `
      );
      let randomCharDelay = getRandomArbitraryNumber(minCharTime, maxCharTime);
      let randomClickDelay = getRandomArbitraryNumber(
        minClickTime,
        maxClickTime
      );
      switch (macroType) {
        case "SearchEngine":
          await executeMacroTypeSearchEngine(
            randomCharDelay,
            randomClickDelay,
            element,
            newJobLog
            // allDetailsOfJob
          );
          break;
        case "PageLink":
          await executeMacroTypePageLink(
            randomCharDelay,
            randomClickDelay,
            element,
            newJobLog
          );
          break;

        case "DirectPage":
          await executeMacroTypeDirectPage(
            randomCharDelay,
            randomClickDelay,
            element,
            newJobLog
          );
          break;

        default:
          console.log(
            "macro type doesn't matched to any specified macro type."
          );
          break;
      }
      console.log("\n --------------Macro order Ended -------------- \n ");
    }

    if (isMicrotypeExcecutedSucceessfully === true) {
      //inserting data for the job log object that all the  microtypes are executed successfully
      await insertDataInDBForSuccess(newJobLog, "Approved");
    }

    if (globalBrowserInstance) {
      await globalBrowserInstance.close();
    }

    //update status of the job
    console.log("\n --------------Job Ended -------------- \n ");
  } catch (error) {
    console.log("error occured after launching puppeteer ", error.message);
    newJobLog.logStatus = "Error";
    newJobLog.logAction = "Done";
    (newJobLog.techMsg = `500 : Failed to launch pupeeteer ${error.message}`),
      (newJobLog.displayMsg = `500 : Failed to launch pupeeteer ${error.message}`);

    let formattedTime = new Date(new Date())
      .toISOString()
      .toString()
      .replace("Z", "")
      .replace("T", " ")
      .split(".")[0];
    newJobLog.endDateTime = formattedTime;

    let ipOfLocalMachine = await publicIp.v4();

    var { country, region, timezone, city } = await geoip.lookup(
      ipOfLocalMachine
    );

    newJobLog.payload = `${ipOfLocalMachine} | ${city} | ${country} | ${region}`;
    await insertDataInJobLog(newJobLog)
      .then((data) => console.log("inserted the exception"))
      .catch((error) => console.log("error in inserting  the exception"));
  }
  //insert data

  scheduleStatus = "Done";
  try {
    const updateStatus = await updateStatusOfJob(scheduleStatus, id);
    console.log(`Status of job with ID ${jobID} updated to ${status}`);
    s;
  } catch (error) {
    console.log("error while updating");
  }
  console.log("\n --------------Job is ended -------------- \n ");
}

function updateStatusOfJob(status, jobId) {
  //updating the job status
  return new Promise((resolve, reject) => {
    dbConn.query(
      `UPDATE jobschedule SET scheduleStatus = '${status}' WHERE id = ${jobId}`,
      function (error, data) {
        if (error) {
          console.log("updated");
          reject(false);
        }
        resolve(true);
      }
    );
  });
}

async function runScheduledJobs() {
  //Job whiich is scheduled  to be executed is loaded
  //in the file using the rundate time and the schedule status
  await dbConn.query(
    "select * from jobschedule where scheduleStatus='Open'",
    async function (err, data, fields) {
      if (err) console.log("error in job schduled ", err.message);
      if (data) {
        //  console.log("daa", data)
        if (data.length > 0) {
          for (let index = 0; index < data.length; index++) {
            //looping on the selected scheduled job

            const element = data[index];
            let { runDateTime } = element;

            console.log("current is ", moment());
            console.log("current is ", moment(runDateTime)); //

            let decideToExecute = moment(runDateTime).isBefore(moment());
            console.log("result is  .....", decideToExecute);

            if (decideToExecute === true) {
              //executing the job one by one
              await sleep(1000 * 10);
              await excecuteJob(element);
            } else {
              console.log("Not executing job right now .....");
              continue;
            }
          }
        } else {
          console.log("\n No jobs for execution right now ..... \n");
        }
      }
    }
  );
}

// runScheduledJobs();

//code for hadnelling unhandled exception and rejection
process.on("uncaughtException", function (err) {
  console.log("uncaught exception occured ===> ", err.message);
  console.log("err stack is ", err.stack);
});

process.on("unhandledRejection", function (err) {
  console.log("unhandled Rejection occured ===> ", err.message);
  console.log("err stack is ", err.stack);
});

function sleep(ms) {
  return new Promise((resolve) => {
    setTimeout(resolve, ms);
  });
}

module.exports = {
  runScheduledJobs,
};
