const turns = [];
let currentBuildings = [];
let currentGridSize = 1;

function serialize(b) {
	return [b.id, b.pos.x, b.pos.y, b.rot, b.flip ? 1 : 0].join(",");
}

function handleBuildingsData(details, changeCurrentBuildings=true) {
	let currentBuildingsCopy;
	let currentGridSizeCopy;
	if (!changeCurrentBuildings) {
		currentGridSizeCopy = currentGridSize;
		currentBuildingsCopy = [...currentBuildings]
	}

	const buildings = details.game.buildings.map((b) => serialize({
		id: b.id,
		pos: b.current_pos,
		rot: Math.round((b.rotation * 2 / Math.PI) % 4),
		flip: b.flipped,
	}));

	let res = [];

	const size = details.game.grid_size;
	if (currentGridSize != size) {
		currentGridSize = size;
		res.push("g" + size);
	}

	for (let i = 0; i < currentBuildings.length; i++) {
		if (!buildings.includes(currentBuildings[i])) {
			res.push(i);
		}
	}
	currentBuildings = currentBuildings.filter((_, i) => !res.includes(i));

	for (const b of buildings) {
		if (!currentBuildings.includes(b)) {
			currentBuildings.push(b);
			res.push(b);
		}
	}
	turns.push(res.join("|"));

	if (!changeCurrentBuildings) {
		currentBuildings = currentBuildingsCopy;
		currentGridSize = currentGridSizeCopy;
		const ret = getReplayData();
		turns.pop();
		return ret;
	}
}

function getReplayData() {
	return turns.join("$");
}

function md5(inputString) {
	let hc = "0123456789abcdef";
	function rh(n) {
		let j,
			s = "";
		for (j = 0; j <= 3; j++)
			s +=
				hc.charAt((n >> (j * 8 + 4)) & 0x0f) + hc.charAt((n >> (j * 8)) & 0x0f);
		return s;
	}
	function ad(x, y) {
		let l = (x & 0xffff) + (y & 0xffff);
		let m = (x >> 16) + (y >> 16) + (l >> 16);
		return (m << 16) | (l & 0xffff);
	}
	function rl(n, c) {
		return (n << c) | (n >>> (32 - c));
	}
	function cm(q, a, b, x, s, t) {
		return ad(rl(ad(ad(a, q), ad(x, t)), s), b);
	}
	function ff(a, b, c, d, x, s, t) {
		return cm((b & c) | (~b & d), a, b, x, s, t);
	}
	function gg(a, b, c, d, x, s, t) {
		return cm((b & d) | (c & ~d), a, b, x, s, t);
	}
	function hh(a, b, c, d, x, s, t) {
		return cm(b ^ c ^ d, a, b, x, s, t);
	}
	function ii(a, b, c, d, x, s, t) {
		return cm(c ^ (b | ~d), a, b, x, s, t);
	}
	function sb(x) {
		let i;
		let nblk = ((x.length + 8) >> 6) + 1;
		let blks = new Array(nblk * 16);
		for (i = 0; i < nblk * 16; i++) blks[i] = 0;
		for (i = 0; i < x.length; i++)
			blks[i >> 2] |= x.charCodeAt(i) << ((i % 4) * 8);
		blks[i >> 2] |= 0x80 << ((i % 4) * 8);
		blks[nblk * 16 - 2] = x.length * 8;
		return blks;
	}
	let i,
		x = sb(inputString),
		a = 1732584193,
		b = -271733879,
		c = -1732584194,
		d = 271733878,
		olda,
		oldb,
		oldc,
		oldd;
	for (i = 0; i < x.length; i += 16) {
		olda = a;
		oldb = b;
		oldc = c;
		oldd = d;
		a = ff(a, b, c, d, x[i + 0], 7, -680876936);
		d = ff(d, a, b, c, x[i + 1], 12, -389564586);
		c = ff(c, d, a, b, x[i + 2], 17, 606105819);
		b = ff(b, c, d, a, x[i + 3], 22, -1044525330);
		a = ff(a, b, c, d, x[i + 4], 7, -176418897);
		d = ff(d, a, b, c, x[i + 5], 12, 1200080426);
		c = ff(c, d, a, b, x[i + 6], 17, -1473231341);
		b = ff(b, c, d, a, x[i + 7], 22, -45705983);
		a = ff(a, b, c, d, x[i + 8], 7, 1770035416);
		d = ff(d, a, b, c, x[i + 9], 12, -1958414417);
		c = ff(c, d, a, b, x[i + 10], 17, -42063);
		b = ff(b, c, d, a, x[i + 11], 22, -1990404162);
		a = ff(a, b, c, d, x[i + 12], 7, 1804603682);
		d = ff(d, a, b, c, x[i + 13], 12, -40341101);
		c = ff(c, d, a, b, x[i + 14], 17, -1502002290);
		b = ff(b, c, d, a, x[i + 15], 22, 1236535329);
		a = gg(a, b, c, d, x[i + 1], 5, -165796510);
		d = gg(d, a, b, c, x[i + 6], 9, -1069501632);
		c = gg(c, d, a, b, x[i + 11], 14, 643717713);
		b = gg(b, c, d, a, x[i + 0], 20, -373897302);
		a = gg(a, b, c, d, x[i + 5], 5, -701558691);
		d = gg(d, a, b, c, x[i + 10], 9, 38016083);
		c = gg(c, d, a, b, x[i + 15], 14, -660478335);
		b = gg(b, c, d, a, x[i + 4], 20, -405537848);
		a = gg(a, b, c, d, x[i + 9], 5, 568446438);
		d = gg(d, a, b, c, x[i + 14], 9, -1019803690);
		c = gg(c, d, a, b, x[i + 3], 14, -187363961);
		b = gg(b, c, d, a, x[i + 8], 20, 1163531501);
		a = gg(a, b, c, d, x[i + 13], 5, -1444681467);
		d = gg(d, a, b, c, x[i + 2], 9, -51403784);
		c = gg(c, d, a, b, x[i + 7], 14, 1735328473);
		b = gg(b, c, d, a, x[i + 12], 20, -1926607734);
		a = hh(a, b, c, d, x[i + 5], 4, -378558);
		d = hh(d, a, b, c, x[i + 8], 11, -2022574463);
		c = hh(c, d, a, b, x[i + 11], 16, 1839030562);
		b = hh(b, c, d, a, x[i + 14], 23, -35309556);
		a = hh(a, b, c, d, x[i + 1], 4, -1530992060);
		d = hh(d, a, b, c, x[i + 4], 11, 1272893353);
		c = hh(c, d, a, b, x[i + 7], 16, -155497632);
		b = hh(b, c, d, a, x[i + 10], 23, -1094730640);
		a = hh(a, b, c, d, x[i + 13], 4, 681279174);
		d = hh(d, a, b, c, x[i + 0], 11, -358537222);
		c = hh(c, d, a, b, x[i + 3], 16, -722521979);
		b = hh(b, c, d, a, x[i + 6], 23, 76029189);
		a = hh(a, b, c, d, x[i + 9], 4, -640364487);
		d = hh(d, a, b, c, x[i + 12], 11, -421815835);
		c = hh(c, d, a, b, x[i + 15], 16, 530742520);
		b = hh(b, c, d, a, x[i + 2], 23, -995338651);
		a = ii(a, b, c, d, x[i + 0], 6, -198630844);
		d = ii(d, a, b, c, x[i + 7], 10, 1126891415);
		c = ii(c, d, a, b, x[i + 14], 15, -1416354905);
		b = ii(b, c, d, a, x[i + 5], 21, -57434055);
		a = ii(a, b, c, d, x[i + 12], 6, 1700485571);
		d = ii(d, a, b, c, x[i + 3], 10, -1894986606);
		c = ii(c, d, a, b, x[i + 10], 15, -1051523);
		b = ii(b, c, d, a, x[i + 1], 21, -2054922799);
		a = ii(a, b, c, d, x[i + 8], 6, 1873313359);
		d = ii(d, a, b, c, x[i + 15], 10, -30611744);
		c = ii(c, d, a, b, x[i + 6], 15, -1560198380);
		b = ii(b, c, d, a, x[i + 13], 21, 1309151649);
		a = ii(a, b, c, d, x[i + 4], 6, -145523070);
		d = ii(d, a, b, c, x[i + 11], 10, -1120210379);
		c = ii(c, d, a, b, x[i + 2], 15, 718787259);
		b = ii(b, c, d, a, x[i + 9], 21, -343485551);
		a = ad(a, olda);
		b = ad(b, oldb);
		c = ad(c, oldc);
		d = ad(d, oldd);
	}
	return rh(a) + rh(b) + rh(c) + rh(d);
}

// Mutual exclusion lock, used for ensuring network requests get sent in order
class Mutex {
	constructor() {
		this.queue = [];
		this.locked = false;
	}

	lock() {
		let res = new Promise((resolve, reject) => {
			this.queue.push(resolve);
		});
		this._poll();
		return res;
	}

	_poll() {
		if (!this.locked && this.queue.length) {
			const resolve = this.queue.shift();
			this.locked = true;
			resolve();
		}
	}

	unlock() {
		this.locked = false;
		this._poll();
	}
}

function sleep(ms) {
	return new Promise((resolve) => setTimeout(resolve, ms));
}

class CapstoneLogger {
	prdUrl =
		"https://integration.centerforgamescience.org/cgs/apps/games/v2/index.php/";
	BUFFER_DURATION = 3000; // milliseconds for buffering level actions
	MAX_RETRIES = 3; // maximum times to retry a failed fetch request
	RETRY_DELAY = 1500; // milliseconds to delay between fetch retries

	constructor(gameId, gameName, gameKey, categoryId) {
		this.gameId = gameId;
		this.gameName = gameName;
		this.gameKey = gameKey;
		this.categoryId = categoryId;
		this.levelActionBuffer = [];
		// Need to keep this at one (another table entry defines the valid version number)
		// To keep things simple, only modify the categoryId to filter data
		this.versionNumber = 1;

		this.mutex = new Mutex();
	}

	// sends a network request to the given URL with the given data
	async _request(url, data) {
		// Standard template data sent for every request
		const stringifiedData = data ? JSON.stringify(data) : null;
		const encodedData = md5((stringifiedData || "") + this.gameKey);
		const requestBlob = {
			dl: "0",
			latency: "5",
			priority: "1",
			de: "0",
			noCache: "",
			cid: this.categoryId + "",
			gid: this.gameId + "",
			data: stringifiedData,
			skey: encodedData,
		};

		const formData = new FormData();
		for (const [k, v] of Object.entries(requestBlob)) {
			formData.append(k, v);
		}

		const payload = {
			method: "POST",
			headers: {
				Accept: "*/*",
				"Content-Type": "application/x-www-form-urlencoded",
			},
			body: new URLSearchParams(formData),
		};

		for (let i = 0; i < this.MAX_RETRIES; i++) {
			try {
				return await fetch(this.prdUrl + url, payload);
			} catch (e) {
				console.error(e);
			}
			await sleep(this.RETRY_DELAY);
		}
		// failed to fetch
		return;
	}

	// Generate a guid for a user, use this to track their actions
	generateUuid() {
		return Array(32)
			.fill()
			.map(
				(_, i) =>
					([8, 12, 16, 20].includes(i) ? "-" : "") +
					Math.floor(Math.random() * 16).toString(16)
			)
			.join("");
	}

	getSavedUserId() {
		return window.localStorage.getItem("saved_userid");
	}

	setSavedUserId(uuid) {
		window.localStorage.setItem("saved_userid", uuid);
	}

	// return parsed JSON if argument is not-null, else null
	parseArgs(jsonString) {
		return jsonString ? JSON.parse(jsonString) : null;
	}

	startNewSession() {
		let uuid = this.getSavedUserId();
		if (!uuid) {
			uuid = this.generateUuid();
			this.setSavedUserId(uuid);
		}
		this.startNewSessionWithUuid(uuid);
		return uuid;
	}

	async startNewSessionWithUuid(userId) {
		// console.log("[START NEW SESSION] uid=", userId);
		await this.mutex.lock();
		this.currentUserId = userId;
		this.currentLevelSeqInSession = 0;
		this.currentActionSeqInSession = 0;

		try {
			const res = await this._request("loggingpageload/set/", {
				eid: 0,
				cid: this.categoryId,
				pl_detail: {},
				client_ts: Date.now(),
				uid: this.currentUserId,
				g_name: this.gameName,
				gid: this.gameId,
				svid: 2,
				vid: this.versionNumber,
			});
			const data = await res.text();

			// Part of the response data should be the session id
			let sessionSuccess = false;
			if (data) {
				const parsedResults = JSON.parse(data.substring(5));
				if (parsedResults.tstatus === "t") {
					this.currentSessionId = parsedResults.r_data.sessionid;
					sessionSuccess = true;
				}
			}
			console.log("sessionSuccess", sessionSuccess);
			console.log("sessionid", this.currentSessionId);
		} catch (e) {
			console.error(e);
		} finally {
			this.mutex.unlock();
		}

	}

	async logLevelStart(levelId, details) {
		await this.mutex.lock();
		details = this.parseArgs(details);
		// console.log("[LOG LEVEL START]", levelId, details);

		try {
			this.flushBufferedLevelActions();
			if (this.levelActionTimer) {
				clearInterval(this.levelActionTimer);
			}
			this.levelActionTimer = setInterval(() => {
				this.flushBufferedLevelActions();
			}, this.BUFFER_DURATION);

			this.timestampOfPrevLevelStart = Date.now();
			this.currentActionSeqInLevel = 0;
			this.currentLevelId = levelId;
			this.currentDqid = null;

			const res = await this._request("quest/start", {
				...this.getCommonData(),
				sessionid: this.currentSessionId,
				sid: this.currentSessionId,
				quest_seqid: ++this.currentLevelSeqInSession,
				qaction_seqid: ++this.currentActionSeqInLevel,
				q_detail: details,
				q_s_id: 1,
				session_seqid: ++this.currentActionSeqInSession,
			});
			const data = await res.text();

			if (data) {
				this.currentDqid = JSON.parse(data.substring(5)).dqid;
			}
		} catch {
		} finally {
			this.mutex.unlock();
		}

	}

	async logLevelEnd(details) {
		await this.mutex.lock();
		details = this.parseArgs(details);
		// console.log("[LOG LEVEL END]", details);
		handleBuildingsData(details);
		details.game.buildings = getReplayData();

		try {
			this.flushBufferedLevelActions();
			if (this.levelActionTimer) {
				clearInterval(this.levelActionTimer);
			}

			await this._request("quest/end", {
				...this.getCommonData(),
				sessionid: this.currentSessionId,
				sid: this.currentSessionId,
				qaction_seqid: ++this.currentActionSeqInLevel,
				q_detail: details,
				q_s_id: 0,
				dqid: this.currentDqid,
				session_seqid: ++this.currentActionSeqInSession,
			});
			this.currentDqid = null;
		} catch {
		} finally {
			this.mutex.unlock();
		}
	}

	// Actions should be buffered and sent at a limited rate
	// (immediately flush if an end occurs or new quest start)
	async logLevelAction(actionId, details) {
		await this.mutex.lock();
		details = this.parseArgs(details);
		// console.log("[LOG LEVEL ACTION]", actionId, details);

		if (actionId === 666 || actionId === 777) {
			// win or lose
			let replay = handleBuildingsData(details, false);
			details.game.buildings = replay;
			console.log(replay);
		}

		// Per action, figure out the time since the start of the level
		const timestampOfAction = Date.now();
		const relativeTime = timestampOfAction - this.timestampOfPrevLevelStart;
		this.levelActionBuffer.push({
			detail: details,
			client_ts: timestampOfAction,
			ts: relativeTime,
			te: relativeTime,
			session_seqid: ++this.currentActionSeqInSession,
			qaction_seqid: ++this.currentActionSeqInLevel,
			aid: actionId,
		});
		this.mutex.unlock();
	}

	async logActionWithNoLevel(actionId, details) {
		await this.mutex.lock();
		details = this.parseArgs(details);
		// console.log("[LOG ACTION NO LEVEL]", actionId, details);

		try {
			this._request("loggingactionnoquest/set/", {
				session_seqid: ++this.currentActionSeqInSession,
				cid: this.categoryId,
				client_ts: Date.now(),
				aid: actionId,
				vid: this.versionNumber,
				uid: this.currentUserId,
				g_name: this.gameName,
				a_detail: details,
				gid: this.gameId,
				svid: 2,
				sessionid: this.currentSessionId,
			});
		} catch {
		} finally {
			this.mutex.unlock();
		}
	}

	async flushBufferedLevelActions() {
		// Don't log any actions until a dqid has been set
		if (this.levelActionBuffer.length > 0 && this.currentDqid != null) {
			try {
				await this._request("logging/set", {
					...this.getCommonData(),
					actions: this.levelActionBuffer,
					dqid: this.currentDqid,
				});
			} catch {
			}
			// Clear out old array
			this.levelActionBuffer = [];
		}
	}

	getCommonData() {
		return {
			client_ts: Date.now(),
			cid: this.categoryId,
			svid: 2,
			lid: 0,
			vid: this.versionNumber,
			qid: this.currentLevelId,
			g_name: this.gameName,
			uid: this.currentUserId,
			g_s_id: this.gameId,
			tid: 0,
			gid: this.gameId,
		};
	}
}

function getLogger(categoryId = 1) {
	window.logger = new CapstoneLogger(
		202206,
		"cev",
		"b626a818a8fc1905b23b3cb9f3fcdf23",
		categoryId
	);
	// window.logger = new CapstoneLogger(202206, "your-game-name", "your-game-key", categoryId);
	return window.logger;
}
