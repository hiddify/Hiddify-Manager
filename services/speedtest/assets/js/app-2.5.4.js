/*
     ©CopyRight 2013-2023 by OpenSpeedTest.COM. All Rights Reserved. 
     Official Website : https://OpenSpeedTest.COM | Email: support@openspeedtest.com
     Developed by : Vishnu | https://Vishnu.Pro | Email : me@vishnu.pro 
     Like this Project? Please Donate NOW & Keep us Alive -> https://go.openspeedtest.com/Donate
    Speed Test by OpenSpeedTest™️ is Free and Open-Source Software (FOSS) with MIT License.
    Read full license terms @ http://go.openspeedtest.com/License
    If you have any Questions, ideas or Comments Please Send it via -> https://go.openspeedtest.com/SendMessage
*/
window.onload = function () {
  var appSVG = document.getElementById("OpenSpeedTest-UI");
  appSVG.parentNode.replaceChild(appSVG.contentDocument.documentElement, appSVG);
  ostOnload();
  OpenSpeedTest.Start();
};
(function (OpenSpeedTest) {
  var Status;
  var ProG;
  var Callback = function (callback) {
    if (callback && typeof callback === "function") {
      callback();
    }
  };
  function _(el) {
    if (!(this instanceof _)) {
      return new _(el);
    }
    this.el = document.getElementById(el);
  }
  _.prototype.fade = function fade(type, ms, callback00) {
    var isIn = type === "in", opacity = isIn ? 0 : 1, interval = 14, duration = ms, gap = interval / duration, self = this;
    if (isIn) {
      self.el.style.display = "block";
      self.el.style.opacity = opacity;
    }
    function func() {
      opacity = isIn ? opacity + gap : opacity - gap;
      self.el.style.opacity = opacity;
      if (opacity <= 0) {
        self.el.style.display = "none";
      }
      if (opacity <= 0 || opacity >= 1) {
        window.clearInterval(fading, Callback(callback00));
      }
    }
    var fading = window.setInterval(func, interval);
  };
  var easeOutQuint = function (t, b, c, d) {
    t /= d;
    t--;
    return c * (t * t * t * t * t + 1) + b;
  };
  var easeOutCubic = function (t, b, c, d) {
    t /= d;
    t--;
    return c * (t * t * t + 1) + b;
  };
  var openSpeedtestShow = function () {
    this.YourIP = _("YourIP");
    this.ipDesk = _("ipDesk");
    this.ipMob = _("ipMob");
    this.downSymbolDesk = _("downSymbolDesk");
    this.upSymbolDesk = _("upSymbolDesk");
    this.upSymbolMob = _("upSymbolMob");
    this.downSymbolMob = _("downSymbolMob");
    this.settingsMob = _("settingsMob");
    this.settingsDesk = _("settingsDesk");
    this.oDoLiveStatus = _("oDoLiveStatus");
    this.ConnectErrorMob = _("ConnectErrorMob");
    this.ConnectErrorDesk = _("ConnectErrorDesk");
    this.downResult = _("downResult");
    this.upRestxt = _("upRestxt");
    this.pingResult = _("pingResult");
    this.jitterDesk = _("jitterDesk");
    this.pingMobres = _("pingMobres");
    this.JitterResultMon = _("JitterResultMon");
    this.JitterResultms = _("JitterResultms");
    this.UI_Desk = _("UI-Desk");
    this.UI_Mob = _("UI-Mob");
    this.oDoTopSpeed = _("oDoTopSpeed");
    this.startButtonMob = _("startButtonMob");
    this.startButtonDesk = _("startButtonDesk");
    this.intro_Desk = _("intro-Desk");
    this.intro_Mob = _("intro-Mob");
    this.loader = _("loading_app");
    this.OpenSpeedtest = _("OpenSpeedtest");
    this.mainGaugebg_Desk = _("mainGaugebg-Desk");
    this.mainGaugeBlue_Desk = _("mainGaugeBlue-Desk");
    this.mainGaugeWhite_Desk = _("mainGaugeWhite-Desk");
    this.mainGaugebg_Mob = _("mainGaugebg-Mob");
    this.mainGaugeBlue_Mob = _("mainGaugeBlue-Mob");
    this.mainGaugeWhite_Mob = _("mainGaugeWhite-Mob");
    this.oDoLiveSpeed = _("oDoLiveSpeed");
    this.progressStatus_Mob = _("progressStatus-Mob");
    this.progressStatus_Desk = _("progressStatus-Desk");
    this.graphc1 = _("graphc1");
    this.graphc2 = _("graphc2");
    this.graphMob2 = _("graphMob2");
    this.graphMob1 = _("graphMob1");
    this.text = _("text");
    this.scale = [{ degree: 680, value: 0 }, { degree: 570, value: 0.5 }, { degree: 460, value: 1 }, { degree: 337, value: 10 }, { degree: 220, value: 100 }, { degree: 115, value: 500 }, { degree: 0, value: 1000 },];
    this.element = "";
    this.chart = "";
    this.polygon = "";
    this.width = 200;
    this.height = 50;
    this.maxValue = 0;
    this.values = [];
    this.points = [];
    this.vSteps = 5;
    this.measurements = [];
    this.points = [];
  };
  openSpeedtestShow.prototype.reset = function () {
    this.element = "";
    this.chart = "";
    this.polygon = "";
    this.width = 200;
    this.height = 50;
    this.maxValue = 0;
    this.values = [];
    this.points = [];
    this.vSteps = 5;
    this.measurements = [];
    this.points = [];
  };
  openSpeedtestShow.prototype.ip = function () {
    var Self = this;
    if (Self.ipDesk.el.style.display === "block") {
      Self.ipDesk.el.style.display = "none";
      Self.ipMob.el.style.display = "none";
    } else {
      Self.ipDesk.el.style.display = "block";
      Self.ipMob.el.style.display = "block";
    }
  };
  openSpeedtestShow.prototype.prePing = function () {
    this.loader.fade("out", 500);
    this.OpenSpeedtest.fade("in", 1000);
  };
  openSpeedtestShow.prototype.app = function () {
    this.loader.fade("out", 500, this.ShowAppIntro());
  };
  openSpeedtestShow.prototype.ShowAppIntro = function () {
    this.OpenSpeedtest.fade("in", 1000);
  };
  openSpeedtestShow.prototype.userInterface = function () {
    var Self = this;
    this.intro_Desk.fade("out", 1000);
    this.intro_Mob.fade("out", 1000, this.ShowUI());
  };
  openSpeedtestShow.prototype.ShowUI = function () {
    this.UI_Desk.fade("in", 1000);
    this.UI_Mob.fade("in", 1000, uiLoaded);
    function uiLoaded(argument) {
      Status = "Loaded";
      console.log("Developed by Vishnu. Email --\x3e me@vishnu.pro");
    }
  };
  openSpeedtestShow.prototype.Symbol = function (dir) {
    if (dir == 0) {
      this.downSymbolMob.el.style.display = "block";
      this.downSymbolDesk.el.style.display = "block";
      this.upSymbolMob.el.style.display = "none";
      this.upSymbolDesk.el.style.display = "none";
    }
    if (dir == 1) {
      this.downSymbolMob.el.style.display = "none";
      this.downSymbolDesk.el.style.display = "none";
      this.upSymbolMob.el.style.display = "block";
      this.upSymbolDesk.el.style.display = "block";
    }
    if (dir == 2) {
      this.downSymbolMob.el.style.display = "none";
      this.downSymbolDesk.el.style.display = "none";
      this.upSymbolMob.el.style.display = "none";
      this.upSymbolDesk.el.style.display = "none";
    }
  };
  openSpeedtestShow.prototype.Graph = function (speed, select) {
    if (!("remove" in Element.prototype)) {
      Element.prototype.remove = function () {
        if (this.parentNode) {
          this.parentNode.removeChild(this);
        }
      };
    }
    var Self = this;
    var Remove;
    if (select === 0) {
      var Graphelement = this.graphc1.el;
      Remove = "line";
      this.graphMob2.el.style.display = "none";
      this.graphMob1.el.style.display = "block";
    } else {
      Graphelement = this.graphc2.el;
      Remove = "line2";
      this.graphMob1.el.style.display = "none";
      this.graphMob2.el.style.display = "block";
    }
    if (!isNaN(speed)) {
      this.values.push(speed);
    } else {
      this.values.push("");
    }
    function calcMeasure() {
      for (x = 0; x < Self.vSteps; x++) {
        var measurement = Math.ceil(Self.maxValue / Self.vSteps * (x + 1));
        Self.measurements.push(measurement);
      }
      Self.measurements.reverse();
    }
    function createChart(element, values) {
      calcMaxValue();
      calcPoints();
      calcMeasure();
      var removeLine = document.getElementsByClassName(Remove);
      while (removeLine.length > 0) {
        removeLine[0].remove();
      }
      Self.polygon = document.createElementNS("http://www.w3.org/2000/svg", "polygon");
      Self.polygon.setAttribute("points", Self.points);
      Self.polygon.setAttribute("class", Remove);
      if (Self.values.length > 1) {
        Graphelement.appendChild(Self.polygon);
      }
    }
    function calcPoints() {
      if (Self.values.length > 1) {
        var points = "0," + Self.height + " ";
        for (x = 0; x < Self.values.length; x++) {
          var perc = Self.values[x] / Self.maxValue;
          var steps = 130 / (Self.values.length - 1);
          var point = (steps * x).toFixed(2) + "," + (Self.height - Self.height * perc).toFixed(2) + " ";
          points += point;
        }
        points += "130," + Self.height;
        Self.points = points;
      }
    }
    var x;
    function calcMaxValue() {
      Self.maxValue = 0;
      for (x = 0; x < Self.values.length; x++) {
        if (Self.values[x] > Self.maxValue) {
          Self.maxValue = Self.values[x];
        }
      }
      Self.maxValue = Math.ceil(Self.maxValue);
    }
    if (speed > 0) {
      createChart(Graphelement, speed);
    }
  };
  openSpeedtestShow.prototype.progress = function (Switch, duration) {
    var Self = this;
    var Stop = duration;
    var Stage = Switch;
    var currTime = Date.now();
    var chan2 = 0 - 400;
    var interval = setInterval(function () {
      var timeNow = (Date.now() - currTime) / 1000;
      var toLeft = easeOutCubic(timeNow, 400, 400, Stop);
      var toRight = easeOutCubic(timeNow, 400, chan2, Stop);
      if (Stage) {
        Self.progressStatus_Desk.el.style.strokeDashoffset = toLeft;
        Self.progressStatus_Mob.el.style.strokeDashoffset = toLeft;
      } else {
        Self.progressStatus_Desk.el.style.strokeDashoffset = toRight;
        Self.progressStatus_Mob.el.style.strokeDashoffset = toRight;
      }
      if (timeNow >= Stop) {
        clearInterval(interval);
        ProG = "done";
        Self.progressStatus_Desk.el.style.strokeDashoffset = 800;
        Self.progressStatus_Mob.el.style.strokeDashoffset = 800;
      }
    }, 14);
  };
  openSpeedtestShow.prototype.mainGaugeProgress = function (currentSpeed) {
    var Self = this;
    var speed = currentSpeed;
    if (speed < 0) {
      speed = 0;
    }
    var mainGaugeOffset = Self.getNonlinearDegree(speed);
    if (currentSpeed > 0) {
      this.mainGaugeBlue_Desk.el.style.strokeOpacity = 1;
      this.mainGaugeWhite_Desk.el.style.strokeOpacity = 1;
      this.mainGaugeBlue_Mob.el.style.strokeOpacity = 1;
      this.mainGaugeWhite_Mob.el.style.strokeOpacity = 1;
      this.mainGaugeBlue_Desk.el.style.strokeDashoffset = mainGaugeOffset;
      this.mainGaugeWhite_Desk.el.style.strokeDashoffset = mainGaugeOffset == 0 ? 1 : mainGaugeOffset + 1;
      this.mainGaugeBlue_Mob.el.style.strokeDashoffset = mainGaugeOffset;
      this.mainGaugeWhite_Mob.el.style.strokeDashoffset = mainGaugeOffset == 0 ? 1 : mainGaugeOffset + 1;
    }
    if (mainGaugeOffset == 0 && speed > 1000) {
      this.mainGaugeBlue_Mob.el.style.strokeDashoffset = mainGaugeOffset >= 681 ? 681 : mainGaugeOffset;
      this.mainGaugeWhite_Mob.el.style.strokeDashoffset = mainGaugeOffset == 0 ? 1 : mainGaugeOffset + 1;
      this.mainGaugeWhite_Desk.el.style.strokeDashoffset = mainGaugeOffset == 0 ? 1 : mainGaugeOffset + 1;
      this.mainGaugeBlue_Desk.el.style.strokeDashoffset = mainGaugeOffset >= 681 ? 681 : mainGaugeOffset;
    } else if (mainGaugeOffset == 0 && speed <= 0) {
      this.mainGaugeBlue_Mob.el.style.strokeDashoffset = 681.1;
      this.mainGaugeWhite_Mob.el.style.strokeDashoffset = 0.1;
      this.mainGaugeWhite_Desk.el.style.strokeDashoffset = 0.1;
      this.mainGaugeBlue_Desk.el.style.strokeDashoffset = 681.1;
    }
  };
  openSpeedtestShow.prototype.showStatus = function (e) {
    this.oDoLiveStatus.el.textContent = e;
  };
  openSpeedtestShow.prototype.ConnectionError = function () {
    this.ConnectErrorMob.el.style.display = "block";
    this.ConnectErrorDesk.el.style.display = "block";
  };
  openSpeedtestShow.prototype.uploadResult = function (upload) {
    if (upload < 1) {
      this.upRestxt.el.textContent = upload.toFixed(3);
    }
    if (upload >= 1 && upload < 9999) {
      this.upRestxt.el.textContent = upload.toFixed(1);
    }
    if (upload >= 10000 && upload < 99999) {
      this.upRestxt.el.textContent = upload.toFixed(1);
      this.upRestxt.el.style.fontSize = "20px";
    }
    if (upload >= 100000) {
      this.upRestxt.el.textContent = upload.toFixed(1);
      this.upRestxt.el.style.fontSize = "18px";
    }
  };
  openSpeedtestShow.prototype.pingResults = function (data, Display) {
    var ShowData = data;
    if (Display === "Ping") {
      if (ShowData >= 1 && ShowData < 10000) {
        this.pingResult.el.textContent = Math.floor(ShowData);
        this.pingMobres.el.textContent = Math.floor(ShowData);
      } else if (ShowData >= 0 && ShowData < 1) {
        if (ShowData == 0) {
          ShowData = 0;
        }
        this.pingResult.el.textContent = ShowData;
        this.pingMobres.el.textContent = ShowData;
      }
    }
    if (Display === "Error") {
      this.oDoLiveSpeed.el.textContent = ShowData;
    }
  };
  openSpeedtestShow.prototype.downloadResult = function (download) {
    if (download < 1) {
      this.downResult.el.textContent = download.toFixed(3);
    }
    if (download >= 1 && download < 9999) {
      this.downResult.el.textContent = download.toFixed(1);
    }
    if (download >= 10000 && download < 99999) {
      this.downResult.el.textContent = download.toFixed(1);
      this.downResult.el.style.fontSize = "20px";
    }
    if (download >= 100000) {
      this.downResult.el.textContent = download.toFixed(1);
      this.downResult.el.style.fontSize = "18px";
    }
  };
  openSpeedtestShow.prototype.jitterResult = function (data, Display) {
    var ShowData = data;
    if (Display === "Jitter") {
      if (ShowData >= 1 && ShowData < 10000) {
        this.jitterDesk.el.textContent = Math.floor(ShowData);
        if (ShowData >= 1 && ShowData < 100) {
          this.JitterResultMon.el.textContent = Math.floor(ShowData);
        }
        if (ShowData >= 100) {
          var kData = (ShowData / 1000).toFixed(1);
          this.JitterResultMon.el.textContent = kData + "k";
        }
      } else if (ShowData >= 0 && ShowData < 1) {
        if (ShowData == 0) {
          ShowData = 0;
        }
        this.jitterDesk.el.textContent = ShowData;
        this.JitterResultMon.el.textContent = ShowData;
      }
    }
  };
  openSpeedtestShow.prototype.LiveSpeed = function (data, Display) {
    var ShowData = data;
    if (Display === "countDown") {
      var speed = ShowData.toFixed(0);
      this.oDoLiveSpeed.el.textContent = speed;
      return;
    }
    if (Display === "speedToZero") {
      if (typeof ShowData == "number") {
        ShowData = ShowData.toFixed(1);
      }
      if (ShowData <= 0) {
        ShowData = 0;
      }
      this.oDoLiveSpeed.el.textContent = ShowData;
      this.oDoTopSpeed.el.textContent = "1000+";
      this.oDoTopSpeed.el.style.fontSize = "16.9px";
      this.oDoTopSpeed.el.style.fill = "gray";
      return;
    }
    if (Display === "Ping") {
      if (ShowData >= 1 && ShowData < 10000) {
        this.oDoLiveSpeed.el.textContent = Math.floor(ShowData);
      } else if (ShowData >= 0 && ShowData < 1) {
        if (ShowData == 0) {
          ShowData = 0;
        }
        this.oDoLiveSpeed.el.textContent = ShowData;
      }
    } else {
      if (ShowData == 0) {
        var speed = ShowData.toFixed(0);
        this.oDoLiveSpeed.el.textContent = speed;
      }
      if (ShowData <= 1 && ShowData > 0) {
        var speed = ShowData.toFixed(3);
        this.oDoLiveSpeed.el.textContent = speed;
      }
      if (ShowData > 1) {
        var speed = ShowData.toFixed(1);
        this.oDoLiveSpeed.el.textContent = speed;
      }
      if (ShowData <= 1000) {
        this.oDoTopSpeed.el.textContent = "1000+";
        this.oDoTopSpeed.el.style.fontSize = "16.9px";
        this.oDoTopSpeed.el.style.fill = "gray";
      }
      if (ShowData >= 1010) {
        this.oDoTopSpeed.el.textContent = Math.floor(ShowData / 1010) * 1000 + "+";
        this.oDoTopSpeed.el.style.fill = "gray";
        this.oDoTopSpeed.el.style.fontSize = "17.2px";
      }
    }
  };
  openSpeedtestShow.prototype.GaugeProgresstoZero = function (currentSpeed, status) {
    var speed = currentSpeed;
    var Self = this;
    var duration = 3;
    if (speed >= 0) {
      var time = Date.now();
      var SpeedtoZero = 0 - speed;
      var interval = setInterval(function () {
        var timeNow = (Date.now() - time) / 1000;
        var speedToZero = easeOutQuint(timeNow, speed, SpeedtoZero, duration);
        Self.LiveSpeed(speedToZero, "speedToZero");
        Self.mainGaugeProgress(speedToZero);
        if (timeNow >= duration || speedToZero <= 0) {
          clearInterval(interval);
          Self.LiveSpeed(0, "speedToZero");
          Self.mainGaugeProgress(0);
          Status = status;
        }
      }, 16);
    }
  };
  openSpeedtestShow.prototype.getNonlinearDegree = function (mega_bps) {
    var i = 0;
    if (0 == mega_bps || mega_bps <= 0 || isNaN(mega_bps)) {
      return 0;
    }
    while (i < this.scale.length) {
      if (mega_bps > this.scale[i].value) {
        i++;
      } else {
        return this.scale[i - 1].degree + (mega_bps - this.scale[i - 1].value) * (this.scale[i].degree - this.scale[i - 1].degree) / (this.scale[i].value - this.scale[i - 1].value);
      }
    }
    return this.scale[this.scale.length - 1].degree;
  };
  var openSpeedtestGet = function () {
    this.OverAllTimeAvg = window.performance.now();
    this.SpeedSamples = [];
    this.FinalSpeed;
  };
  openSpeedtestGet.prototype.reset = function () {
    this.OverAllTimeAvg = window.performance.now();
    this.SpeedSamples = [];
    this.FinalSpeed = 0;
  };
  openSpeedtestGet.prototype.ArraySum = function (Arr) {
    var array = Arr;
    if (array) {
      var sum = array.reduce(function (A, B) {
        if (typeof A === "number" && typeof B === "number") {
          return A + B;
        }
      }, 0);
      return sum;
    } else {
      return 0;
    }
  };
  openSpeedtestGet.prototype.AvgSpeed = function (Livespeed, Start, duration) {
    var Self = this;
    this.timeNow = (window.performance.now() - this.OverAllTimeAvg) / 1000;
    this.FinalSpeed;
    var StartRecoding = Start;
    StartRecoding = duration - StartRecoding;
    if (this.timeNow >= StartRecoding) {
      if (Livespeed > 0) {
        this.SpeedSamples.push(Livespeed);
      }
      Self.FinalSpeed = Self.ArraySum(Self.SpeedSamples) / Self.SpeedSamples.length;
    }
    return Self.FinalSpeed;
  };
  openSpeedtestGet.prototype.uRandom = function (size, callback) {
    var size = size;
    var randomValue = new Uint32Array(262144);
    function getRandom() {
      var n = randomValue.length;
      for (var i = 0; i < n; i++) {
        randomValue[i] = Math.random() * 4294967296;
      }
      return randomValue;
    }
    var randomData = [];
    var genData = function (dataSize) {
      var dataSize = dataSize;
      for (var i = 0; i < dataSize; i++) {
        randomData[i] = getRandom();
      }
      return randomData;
    };
    return new Blob(genData(size), { type: "application/octet-stream" }, Callback(callback));
  };
  openSpeedtestGet.prototype.addEvt = function (o, e, f) {
    o.addEventListener(e, f);
  };
  openSpeedtestGet.prototype.remEvt = function (o, e, f) {
    o.removeEventListener(e, f);
  };
  var openSpeedtestEngine = function () {
    var Get = new openSpeedtestGet();
    var Show = new openSpeedtestShow();
    Show.app();
    var SendData;
    var myhostName = location.hostname;
    var key;
    var TestServerip;
    var downloadSpeed;
    var uploadSpeed;
    var dataUsedfordl;
    var dataUsedforul;
    var pingEstimate;
    var jitterEstimate;
    var logData;
    var return_data;
    var ReQ = [];
    var StartTime = [];
    var CurrentTime = [];
    var LiveSpeedArr;
    var dLoaded = 0;
    var uLoaded = 0;
    var currentSpeed = 0;
    var uploadTimeing;
    var downloadTimeing;
    var downloadTime;
    var uploadTime;
    var saveTestData;
    var stop = 0;
    function reSett() {
      StartTime = 0;
      CurrentTime = 0;
      LiveSpeedArr = 0;
      currentSpeed = 0;
    }
    var userAgentString;
    if (window.navigator.userAgent) {
      userAgentString = window.navigator.userAgent;
    } else {
      userAgentString = "Not Found";
    }
    var ulFinal = ulDuration * 0.6;
    var dlFinal = dlDuration * 0.6;
    function setFinal() {
      if (ulDuration * 0.6 >= 7) {
        ulFinal = 7;
      }
      if (dlDuration * 0.6 >= 7) {
        dlFinal = 7;
      }
    }
    setFinal();
    var launch = true;
    var init = true;
    Get.addEvt(Show.settingsMob.el, "click", ShowIP);
    Get.addEvt(Show.settingsDesk.el, "click", ShowIP);
    Get.addEvt(Show.startButtonDesk.el, "click", runTasks);
    Get.addEvt(Show.startButtonMob.el, "click", runTasks);
    Get.addEvt(document, "keypress", hiEnter);
    var addEvent = true;
    var getParams = function (url) {
      var params = {};
      var parser = document.createElement("a");
      parser.href = url;
      var query = parser.search.substring(1);
      var vars = query.split("&");
      for (var i = 0; i < vars.length; i++) {
        var pair = vars[i].split("=");
        params[pair[0]] = decodeURIComponent(pair[1]);
      }
      return params;
    };
    var getCommand = getParams(window.location.href.toLowerCase());
    if (setPingSamples) {
      if (typeof getCommand.ping === "string" || typeof getCommand.p === "string") {
        var setPing;
        if (typeof getCommand.ping !== "undefined") {
          setPing = getCommand.ping;
        } else if (typeof getCommand.p !== "undefined") {
          setPing = getCommand.p;
        }
        if (setPing > 0) {
          pingSamples = setPing;
          pingSamples = setPing;
        }
      }
    }
    if (setPingTimeout) {
      if (typeof getCommand.out === "string" || typeof getCommand.o === "string") {
        var setOut;
        if (typeof getCommand.out !== "undefined") {
          setOut = getCommand.out;
        } else if (typeof getCommand.o !== "undefined") {
          setOut = getCommand.o;
        }
        if (setOut > 1) {
          pingTimeOut = setOut;
          pingTimeOut = setOut;
        }
      }
    }
    if (setHTTPReq) {
      if (typeof getCommand.xhr === "string" || typeof getCommand.x === "string") {
        var setThreads;
        if (typeof getCommand.xhr !== "undefined") {
          setThreads = getCommand.xhr;
        } else if (typeof getCommand.x !== "undefined") {
          setThreads = getCommand.x;
        }
        if (setThreads > 0 && setThreads <= 32) {
          dlThreads = setThreads;
          ulThreads = setThreads;
        }
      }
    }
    function isValidHttpUrl(str) {
      var regex = /(?:https?):\/\/(\w+:?\w*)?(\S+)(:\d+)?(\/|\/([\w#!:.?+=&%!\-\/]))?/;
      if (!regex.test(str)) {
        return false;
      } else {
        return true;
      }
    }
    if (selectServer) {
      if (typeof getCommand.host === "string" || typeof getCommand.h === "string") {
        var severAddress;
        if (typeof getCommand.host !== "undefined") {
          severAddress = getCommand.host;
        } else if (typeof getCommand.h !== "undefined") {
          severAddress = getCommand.h;
        }
        if (isValidHttpUrl(severAddress)) {
          openSpeedTestServerList = [{ ServerName: "Home", Download: severAddress + "/downloading", Upload: severAddress + "/upload", ServerIcon: "DefaultIcon", },];
        }
      }
    }
    var custom = parseInt(getCommand.stress);
    var customS = parseInt(getCommand.s);
    var runStress;
    var runStressCustom;
    if (typeof getCommand.stress === "string") {
      runStress = getCommand.stress;
      runStressCustom = custom;
    } else if (typeof getCommand.s === "string") {
      runStress = getCommand.s;
      runStressCustom = customS;
    }
    if (runStress && stressTest) {
      if (runStress === "low" || runStress === "l") {
        dlDuration = 300;
        ulDuration = 300;
      }
      if (runStress === "medium" || runStress === "m") {
        dlDuration = 600;
        ulDuration = 600;
      }
      if (runStress === "high" || runStress === "h") {
        dlDuration = 900;
        ulDuration = 900;
      }
      if (runStress === "veryhigh" || runStress === "v") {
        dlDuration = 1800;
        ulDuration = 1800;
      }
      if (runStress === "extreme" || runStress === "e") {
        dlDuration = 3600;
        ulDuration = 3600;
      }
      if (runStress === "day" || runStress === "d") {
        dlDuration = 86400;
        ulDuration = 86400;
      }
      if (runStress === "year" || runStress === "y") {
        dlDuration = 31557600;
        ulDuration = 31557600;
      }
      if (custom > 12 || customS > 12) {
        dlDuration = runStressCustom;
        ulDuration = runStressCustom;
      }
    }
    var overheadClean = parseInt(getCommand.clean);
    var overheadCleanC = parseInt(getCommand.c);
    var customOverHeadValue = 1;
    if (overheadClean) {
      customOverHeadValue = overheadClean;
    } else if (overheadCleanC) {
      customOverHeadValue = overheadCleanC;
    }
    if (enableClean) {
      if (typeof getCommand.clean === "string" || typeof getCommand.c === "string") {
        if (overheadClean >= 1 || overheadCleanC >= 1) {
          if (overheadClean < 5 || overheadCleanC < 5) {
            upAdjust = 1 + customOverHeadValue / 100;
            dlAdjust = 1 + customOverHeadValue / 100;
          }
        } else {
          upAdjust = 1;
          dlAdjust = 1;
        }
      }
    }
    var OpenSpeedTestRun = parseInt(getCommand.run);
    var OpenSpeedTestRunR = parseInt(getCommand.r);
    var OpenSpeedTestStart;
    if (enableRun) {
      if (typeof getCommand.run === "string" || typeof getCommand.r === "string") {
        if (OpenSpeedTestRun > 0) {
          OpenSpeedTestStart = OpenSpeedTestRun;
        } else if (OpenSpeedTestRunR > 0) {
          OpenSpeedTestStart = OpenSpeedTestRunR;
        } else {
          OpenSpeedTestStart = 0;
        }
      }
    }
    if (OpenSpeedTestStart >= 0) {
      if (launch) {
        runTasks();
      }
    }
    var runTest = getCommand.test;
    var runTestT = getCommand.t;
    var SelectTest = false;
    if (selectTest) {
      if (typeof runTest === "string" || typeof runTestT === "string") {
        var runTestC;
        if (runTest) {
          runTestC = runTest;
          SelectTest = runTest;
        } else if (runTestT) {
          runTestC = runTestT;
          SelectTest = runTestT;
        }
        if (runTestC === "download" || runTestC === "d") {
          uploadSpeed = 0;
          dataUsedforul = 0;
          SelectTest = "Download";
          if (launch) {
            runTasks();
          }
        } else if (runTestC === "upload" || runTestC === "u") {
          downloadSpeed = 0;
          dataUsedfordl = 0;
          SelectTest = "Upload";
          stop = 1;
          if (launch) {
            runTasks();
          }
        } else if (runTestC === "ping" || runTestC === "p") {
          uploadSpeed = 0;
          dataUsedforul = 0;
          downloadSpeed = 0;
          dataUsedfordl = 0;
          SelectTest = "Ping";
          if (launch) {
            runTasks();
          }
        } else {
          SelectTest = false;
        }
      }
    }
    var Startit = 0;
    function removeEvts() {
      Get.remEvt(Show.settingsMob.el, "click", ShowIP);
      Get.remEvt(Show.settingsDesk.el, "click", ShowIP);
      Get.remEvt(Show.startButtonDesk.el, "click", runTasks);
      Get.remEvt(Show.startButtonMob.el, "click", runTasks);
      Get.remEvt(document, "keypress", hiEnter);
    }
    var requestIP = false;
    function ShowIP() {
      if (requestIP) {
        Show.YourIP.el.textContent = "Please wait..";
        ServerConnect(7);
        requestIP = false;
      }
      Show.ip();
    }
    function runTasks() {
      if (addEvent) {
        removeEvts();
        addEvent = false;
      }
      if (OpenSpeedTestStart >= 0) {
        launch = false;
        Show.userInterface();
        init = false;
        var AutoTme = Math.ceil(Math.abs(OpenSpeedTestStart));
        Show.showStatus("Automatic Test Starts in ...");
        var autoTest = setInterval(countDownF, 1000);
      }
      function countDownF() {
        if (AutoTme >= 1) {
          AutoTme = AutoTme - 1;
          Show.LiveSpeed(AutoTme, "countDown");
        } else {
          if (AutoTme <= 0) {
            clearInterval(autoTest);
            launch = true;
            OpenSpeedTestStart = undefined;
            runTasks();
          }
        }
      }
      if (openSpeedTestServerList === "fetch" && launch === true) {
        launch = false;
        Show.showStatus("Fetching Server Info..");
        ServerConnect(6);
      }
      if (launch === true) {
        if (SelectTest === "Ping") {
          testRun();
        } else if (SelectTest === "Download") {
          testRun();
        } else if (SelectTest === "Upload") {
          testRun();
        } else if (SelectTest === false) {
          testRun();
        }
      }
    }
    var osttm = "\u2122";
    var myname = "Hiddify";
    var com = ".com";
    var ost = "Hiddify";
    function hiEnter(e) {
      if (e.key === "Enter") {
        runTasks();
      }
    }
    var showResult = 0;
    if (openChannel === "web") {
      showResult = webRe;
      requestIP = true;
    }
    if (openChannel === "widget") {
      showResult = widgetRe;
      requestIP = true;
    }
    if (openChannel === "selfwidget") {
      showResult = widgetRe;
      TestServerip = domainx;
      myhostName = TestServerip;
    }
    if (openChannel === "dev") {
    }
    function testRun() {
      if (init) {
        Show.userInterface();
        init = false;
      }
      OpenSpeedtest();
    }
    function OpenSpeedtest() {
      if (openChannel === "widget" || openChannel === "web") {
        ServerConnect(1);
      }
      function readyToUP() {
        uploadTime = window.performance.now();
        upReq();
      }
      var Engine = setInterval(function () {
        if (Status === "Loaded") {
          Status = "busy";
          sendPing(0);
        }
        if (Status === "Ping") {
          Status = "busy";
          Show.showStatus("Milliseconds");
        }
        if (Status === "Download") {
          Show.showStatus("Initializing..");
          Get.reset();
          reSett();
          Show.reset();
          downloadTime = window.performance.now();
          downReq();
          Status = "initDown";
        }
        if (Status === "Downloading") {
          Show.Symbol(0);
          if (Startit == 0) {
            Startit = 1;
            Show.showStatus("Testing download speed..");
            var extraTime = (window.performance.now() - downloadTime) / 1000;
            dReset = extraTime;
            Show.progress(1, dlDuration + 2.5);
            dlDuration += extraTime;
          }
          downloadTimeing = (window.performance.now() - downloadTime) / 1000;
          reportCurrentSpeed("dl");
          Show.showStatus("Mbps download");
          Show.mainGaugeProgress(currentSpeed);
          Show.LiveSpeed(currentSpeed);
          Show.Graph(currentSpeed, 0);
          downloadSpeed = Get.AvgSpeed(currentSpeed, dlFinal, dlDuration);
          if (downloadTimeing >= dlDuration && ProG == "done") {
            if (SelectTest) {
              Show.GaugeProgresstoZero(currentSpeed, "SendR");
              Show.showStatus("All done");
              Show.Symbol(2);
            } else {
              Show.GaugeProgresstoZero(currentSpeed, "Upload");
            }
            Show.downloadResult(downloadSpeed);
            dataUsedfordl = dLoaded;
            stop = 1;
            Status = "busy";
            reSett();
            Get.reset();
          }
        }
        if (Status == "Upload") {
          if (stop === 1) {
            Show.Symbol(1);
            Status = "initup";
            Show.showStatus("Initializing..");
            Show.LiveSpeed("...", "speedToZero");
            SendData = Get.uRandom(ulDataSize, readyToUP);
            if (SelectTest) {
              Startit = 1;
            }
          }
        }
        if (Status === "Uploading") {
          if (Startit == 1) {
            Startit = 2;
            Show.showStatus("Testing upload speed..");
            currentSpeed = 0;
            Get.reset();
            Show.reset();
            var extraUTime = (window.performance.now() - uploadTime) / 1000;
            uReset = extraUTime;
            Show.progress(false, ulDuration + 2.5);
            ulDuration += extraUTime;
          }
          Show.showStatus("Mbps upload");
          uploadTimeing = (window.performance.now() - uploadTime) / 1000;
          reportCurrentSpeed("up");
          Show.mainGaugeProgress(currentSpeed);
          Show.LiveSpeed(currentSpeed);
          Show.Graph(currentSpeed, 1);
          uploadSpeed = Get.AvgSpeed(currentSpeed, ulFinal, ulDuration);
          if (uploadTimeing >= ulDuration && stop == 1) {
            dataUsedforul = uLoaded;
            Show.uploadResult(uploadSpeed);
            Show.GaugeProgresstoZero(currentSpeed, "SendR");
            SendData = undefined;
            Show.showStatus("All done");
            Show.Symbol(2);
            Status = "busy";
            stop = 0;
          }
        }
        if (Status === "Error") {
          Show.showStatus("Check your network connection status.");
          Show.ConnectionError();
          Status = "busy";
          clearInterval(Engine);
          var dummyElement = document.createElement("div");
          dummyElement.innerHTML = '<a xlink:href="https://openspeedtest.com/FAQ.php?ref=NetworkError" style="cursor: pointer" target="_blank"></a>';
          var htmlAnchorElement = dummyElement.querySelector("a");
          Show.oDoLiveSpeed.el.textContent = "Network Error";
          var circleSVG = document.getElementById("oDoLiveSpeed");
          htmlAnchorElement.innerHTML = circleSVG.innerHTML;
          circleSVG.innerHTML = dummyElement.innerHTML;
        }
        if (Status === "SendR") {
          Show.showStatus("All done");
          var dummyElement = document.createElement("div");
          dummyElement.innerHTML = '<a xlink:href="https://github.com/hiddify/hiddify-manager/wiki/" style="cursor: pointer" target="_blank"></a>';
          var htmlAnchorElement = dummyElement.querySelector("a");
          Show.oDoLiveSpeed.el.textContent = ost;
          var circleSVG = document.getElementById("oDoLiveSpeed");
          htmlAnchorElement.innerHTML = circleSVG.innerHTML;
          circleSVG.innerHTML = dummyElement.innerHTML;
          if (location.hostname != myname.toLowerCase() + com) {
            saveTestData = "https://" + myname.toLowerCase() + com + "/results/show.php?" + "&d=" + downloadSpeed.toFixed(3) + "&u=" + uploadSpeed.toFixed(3) + "&p=" + pingEstimate + "&j=" + jitterEstimate + "&dd=" + (dataUsedfordl / 1048576).toFixed(3) + "&ud=" + (dataUsedforul / 1048576).toFixed(3) + "&ua=" + userAgentString;
            saveTestData = encodeURI(saveTestData);
            var circleSVG2 = document.getElementById("resultsData");
            circleSVG2.setAttributeNS("http://www.w3.org/1999/xlink", "xlink:href", saveTestData);
            circleSVG2.setAttribute("target", "_blank");
            if (saveData) {
              ServerConnect(5);
            }
          } else {
            ServerConnect(3);
          }
          Status = "busy";
          clearInterval(Engine);
        }
      }, 100);
    }
    function downReq() {
      for (var i = 0; i < dlThreads; i++) {
        setTimeout(function (i) {
          SendReQ(i);
        }, dlDelay * i, i);
      }
    }
    function upReq() {
      for (var i = 0; i < ulThreads; i++) {
        setTimeout(function (i) {
          SendUpReq(i);
        }, ulDelay * i, i);
      }
    }
    var dLoad = 0;
    var dDiff = 0;
    var dTotal = 0;
    var dtLoad = 0;
    var dtDiff = 0;
    var dtTotal = 0;
    var dRest = 0;
    var dReset;
    var uReset;
    var uLoad = 0;
    var uDiff = 0;
    var uTotal = 0;
    var utLoad = 0;
    var utDiff = 0;
    var utTotal = 0;
    var uRest = 0;
    var dualReset;
    var neXT = dlDuration * 1000 - 6000;
    var dualupReset;
    var neXTUp = ulDuration * 1000 - 6000;
    function reportCurrentSpeed(now) {
      if (now === "dl") {
        var dTime = downloadTimeing * 1000;
        if (dTime > dReset * 1000 + dlFinal / 2 * 1000 && dRest === 0) {
          dRest = 1;
          dtTotal = dtTotal * 0.01;
          dTotal = dTotal * 0.01;
          dualReset = dTime + 10000;
        }
        if (dTime >= dualReset && dualReset < neXT) {
          dualReset += 10000;
          dtTotal = dtTotal * 0.01;
          dTotal = dTotal * 0.01;
        }
        dLoad = dLoaded <= 0 ? 0 : dLoaded - dDiff;
        dDiff = dLoaded;
        dTotal += dLoad;
        dtLoad = dtDiff = 0 ? 0 : dTime - dtDiff;
        dtDiff = dTime;
        dtTotal += dtLoad;
        if (dTotal > 0) {
          LiveSpeedArr = dTotal / dtTotal / 125 * upAdjust;
          currentSpeed = LiveSpeedArr;
        }
      }
      if (now === "up") {
        var Tym = uploadTimeing * 1000;
        if (Tym > uReset * 1000 + ulFinal / 2 * 1000 && uRest === 0) {
          uRest = 1;
          utTotal = utTotal * 0.1;
          uTotal = uTotal * 0.1;
          dualupReset = Tym + 10000;
        }
        if (Tym >= dualupReset && dualupReset < neXTUp) {
          dualupReset += 10000;
          utTotal = utTotal * 0.1;
          uTotal = uTotal * 0.1;
        }
        uLoad = uLoaded <= 0 ? 0 : uLoaded - uDiff;
        uDiff = uLoaded;
        uTotal += uLoad;
        utLoad = utDiff = 0 ? 0 : Tym - utDiff;
        utDiff = Tym;
        utTotal += utLoad;
        if (uTotal > 0) {
          LiveSpeedArr = uTotal / utTotal / 125 * upAdjust;
          currentSpeed = LiveSpeedArr;
        }
      }
    }
    function SendReQ(i) {
      var lastLoaded = 0;
      var OST = new XMLHttpRequest();
      ReQ[i] = OST;
      ReQ[i].open("GET", fianlPingServer.Download + "?n=" + Math.random(), true);
      ReQ[i].onprogress = function (e) {
        if (stop === 1) {
          ReQ[i].abort();
          ReQ[i] = null;
          ReQ[i] = undefined;
          delete ReQ[i];
          return false;
        }
        if (Status == "initDown") {
          Status = "Downloading";
        }
        var eLoaded = e.loaded <= 0 ? 0 : e.loaded - lastLoaded;
        if (isNaN(eLoaded) || !isFinite(eLoaded) || eLoaded < 0) {
          return false;
        }
        dLoaded += eLoaded;
        lastLoaded = e.loaded;
      };
      ReQ[i].onload = function (e) {
        if (lastLoaded === 0) {
          dLoaded += e.total;
        }
        if (Status == "initDown") {
          Status = "Downloading";
        }
        if (ReQ[i]) {
          ReQ[i].abort();
          ReQ[i] = null;
          ReQ[i] = undefined;
          delete ReQ[i];
        }
        if (stop === 0) {
          SendReQ(i);
        }
      };
      ReQ[i].onerror = function (e) {
        if (stop === 0) {
          SendReQ(i);
        }
      };
      ReQ[i].responseType = "arraybuffer";
      ReQ[i].send();
    }
    var uReQ = [];
    function SendUpReq(i) {
      var lastULoaded = 0;
      var OST = new XMLHttpRequest();
      uReQ[i] = OST;
      uReQ[i].open("POST", fianlPingServer.Upload + "?n=" + Math.random(), true);
      uReQ[i].upload.onprogress = function (e) {
        if (Status == "initup" && some === undefined) {
          var some;
          Status = "Uploading";
        }
        if (uploadTimeing >= ulDuration) {
          uReQ[i].abort();
          uReQ[i] = null;
          uReQ[i] = undefined;
          delete uReQ[i];
          return false;
        }
        var eLoaded = e.loaded <= 0 ? 0 : e.loaded - lastULoaded;
        if (isNaN(eLoaded) || !isFinite(eLoaded) || eLoaded < 0) {
          return false;
        }
        uLoaded += eLoaded;
        lastULoaded = e.loaded;
      };
      uReQ[i].onload = function () {
        if (lastULoaded === 0) {
          uLoaded += ulDataSize * 1048576;
          if (uploadTimeing >= ulDuration) {
            uReQ[i].abort();
            uReQ[i] = null;
            uReQ[i] = undefined;
            delete uReQ[i];
            return false;
          }
        }
        if (Status == "initup" && some === undefined) {
          var some;
          Status = "Uploading";
        }
        if (uReQ[i]) {
          uReQ[i].abort();
          uReQ[i] = null;
          uReQ[i] = undefined;
          delete uReQ[i];
        }
        if (stop === 1) {
          SendUpReq(i);
        }
      };
      uReQ[i].onerror = function (e) {
        if (uploadTimeing <= ulDuration) {
          SendUpReq(i);
        }
      };
      uReQ[i].setRequestHeader("Content-Type", "application/octet-stream");
      if (i > 0 && uLoaded <= 17000) {
      } else {
        uReQ[i].send(SendData);
      }
    }
    function sendPing() {
      readServerList();
    }
    var fianlPingServer;
    var statusPing;
    var statusPingFinal;
    var statusJitter;
    var statusJitterFinal;
    var statusPingTest;
    var pingSendStatus = -1;
    var finalPing = [];
    var pingServer = [];
    var finalJitter = [];
    var pingSendLength = openSpeedTestServerList.length;
    function readServerList() {
      pingSendLength = openSpeedTestServerList.length;
      Status = "Ping";
      performance.clearResourceTimings();
      if (pingSendStatus < pingSendLength - 1) {
        pingSendStatus++;
        if (statusPingTest != "Stop") {
          sendPingRequest(openSpeedTestServerList[pingSendStatus], readServerList);
        }
      } else {
        if (pingServer.length >= 1) {
          var finalLeastPingResult = Math.min.apply(Math, finalPing);
          var finalLeastPingResultIndex = finalPing.indexOf(finalLeastPingResult);
          fianlPingServer = pingServer[finalLeastPingResultIndex];
          statusPingFinal = finalLeastPingResult;
          statusJitterFinal = finalJitter[finalLeastPingResultIndex];
          statusPingTest = "Busy";
          Show.LiveSpeed(statusPingFinal, "Ping");
          Show.pingResults(statusPingFinal, "Ping");
          Show.jitterResult(statusJitterFinal, "Jitter");
          pingEstimate = statusPingFinal;
          jitterEstimate = statusJitterFinal;
          if (SelectTest) {
            if (SelectTest == "Ping") {
              Status = "SendR";
            } else {
              Status = SelectTest;
            }
          } else {
            Status = "Download";
          }
        } else {
          if (pingServer.Download) {
          } else {
            Status = "Error";
          }
        }
      }
    }
    function sendPingRequest(serverListElm, callback) {
      var pingSamplesSend = 0;
      var pingResult = [];
      var jitterResult = [];
      function sendNewPingReq() {
        if (pingSamplesSend < pingSamples) {
          pingSamplesSend++;
          if (statusPingTest != "Stop") {
            PingRequest();
          }
        } else {
          if (pingResult.length > 1) {
            jitterResult.sort(function (a, b) {
              return a - b;
            });
            jitterResult = jitterResult.slice(0, jitterResult.length * jitterFinalSample);
            jitterResult = jitterResult.reduce(function (acc, val) {
              return acc + val;
            }, 0) / jitterResult.length;
            var leastJitter = jitterResult.toFixed(1);
            var leastPing = Math.min.apply(Math, pingResult);
            finalPing.push(leastPing);
            pingServer.push(serverListElm);
            finalJitter.push(leastJitter);
            if (typeof callback === "function") {
              callback();
            }
          } else {
            if (typeof callback === "function") {
              callback();
            }
          }
        }
      }
      function PingRequest() {
        var OST = new XMLHttpRequest();
        var ReQ = OST;
        if (statusPingTest != "Stop") {
          ReQ.abort();
        }
        ReQ.open(pingMethod, serverListElm[pingFile] + "?n=" + Math.random(), true);
        ReQ.timeout = pingTimeOut;
        var startTime = window.performance.now();
        ReQ.send();
        ReQ.onload = function () {
          if (this.status === 200 && this.readyState === 4) {
            var endTime = Math.floor(window.performance.now() - startTime);
            var perfNum = performance.getEntries();
            perfNum = perfNum[perfNum.length - 1];
            var perfPing;
            if (perfNum.initiatorType === "xmlhttprequest") {
              perfPing = parseFloat(perfNum.duration.toFixed(1));
            } else {
              perfPing = endTime;
            }
            if (pingSamplesSend > 250) {
              perfPing = endTime;
            }
            if (perfPing <= 0) {
              statusPing = 0.1;
              pingResult.push(0.1);
            } else {
              statusPing = perfPing;
              pingResult.push(perfPing);
            }
            if (pingResult.length > 1) {
              var jitterCalc = Math.abs(pingResult[pingResult.length - 1] - pingResult[pingResult.length - 2]).toFixed(1);
              jitterResult.push(parseFloat(jitterCalc));
              statusJitter = jitterCalc;
              Show.LiveSpeed(perfPing, "Ping");
              Show.pingResults(perfPing, "Ping");
              Show.jitterResult(jitterCalc, "Jitter");
            }
            sendNewPingReq();
          }
          if (this.status === 404 && this.readyState === 4) {
            pingSamplesSend++;
            sendNewPingReq();
          }
        };
        ReQ.onerror = function (e) {
          pingSamplesSend++;
          sendNewPingReq();
        };
        ReQ.ontimeout = function (e) {
          pingSamplesSend++;
          sendNewPingReq();
        };
      }
      PingRequest();
    }
    var ServerConnect = function (auth) {
      var Self = this;
      var xhr = new XMLHttpRequest();
      var url = OpenSpeedTestdb;
      if (auth == 1) {
        url = webIP;
      }
      if (auth == 5) {
        url = saveDataURL;
      }
      if (auth == 7) {
        url = get_IP;
      }
      xhr.open("POST", url, true);
      xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
      xhr.onreadystatechange = function () {
        if (xhr.readyState == 4 && xhr.status == 200) {
          return_data = xhr.responseText.trim();
          if (auth == 2) {
            key = return_data;
          }
          if (auth == 1) {
            TestServerip = return_data;
          }
          if (auth == 3) {
            setTimeout(function () {
              location.href = showResult + return_data;
            }, 1500);
          }
          if (auth == 6) {
            openSpeedTestServerList = JSON.parse(return_data);
            launch = true;
            runTasks();
          }
          if (auth == 7) {
            Show.YourIP.el.textContent = return_data;
          }
        }
      };
      if (auth == 2) {
        logData = "r=n";
      }
      if (auth == 3) {
        logData = "r=l" + "&d=" + downloadSpeed + "&u=" + uploadSpeed + "&dd=" + dataUsedfordl / 1048576 + "&ud=" + dataUsedforul / 1048576 + "&p=" + pingEstimate + "&do=" + myhostName + "&S=" + key + "&sip=" + TestServerip + "&jit=" + jitterEstimate + "&ua=" + userAgentString;
      }
      if (auth == 5) {
        logData = saveTestData;
      }
      if (auth == 6) {
        logData = "r=s";
      }
      xhr.send(logData);
    };
  };
  OpenSpeedTest.Start = function () {
    new openSpeedtestEngine();
  };
})(window.OpenSpeedTest = window.OpenSpeedTest || {});
