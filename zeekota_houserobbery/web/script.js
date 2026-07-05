const state = {
    visible: false,
    tab: 'dashboard',
    dashboard: null,
    selectedHouseId: null,
    toastCount: 0,
    minigame: null
};

const tabs = [
    { id: 'dashboard', label: 'Dashboard', icon: 'DB' },
    { id: 'contracts', label: 'Contracts', icon: 'CT' },
    { id: 'progression', label: 'Progression', icon: 'XP' },
    { id: 'stats', label: 'Stats', icon: 'ST' },
    { id: 'active', label: 'Active Job', icon: 'AJ' }
];

const app = document.getElementById('app');
const tabsNode = document.getElementById('tabs');
const content = document.getElementById('content');
const viewTitle = document.getElementById('viewTitle');
const activeStrip = document.getElementById('activeStrip');
const closeBtn = document.getElementById('closeBtn');
const minigameNode = document.getElementById('minigame');
const keypadGrid = document.getElementById('keypadGrid');
const sequenceNode = document.getElementById('sequence');
const miniReadout = document.getElementById('miniReadout');
const miniAttempt = document.getElementById('miniAttempt');
const miniTier = document.getElementById('miniTier');
const timerBar = document.getElementById('timerBar');
const screenPrompt = document.getElementById('screenPrompt');
const promptKey = document.getElementById('promptKey');
const promptMessage = document.getElementById('promptMessage');

function resourceName() {
    if (typeof GetParentResourceName === 'function') {
        return GetParentResourceName();
    }
    return 'zeekota_houserobbery';
}

async function post(action, data = {}) {
    try {
        const response = await fetch(`https://${resourceName()}/${action}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify(data)
        });
        return await response.json();
    } catch (error) {
        return { ok: false, error: String(error) };
    }
}

function escapeHtml(value) {
    return String(value ?? '')
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#039;');
}

function money(value) {
    const prefix = state.dashboard?.brand?.moneyPrefix || '$';
    return `${prefix}${Number(value || 0).toLocaleString()}`;
}

function seconds(value) {
    const total = Math.max(0, Number(value || 0));
    const minutes = Math.floor(total / 60);
    const secs = total % 60;
    if (minutes <= 0) return `${secs}s`;
    return `${minutes}m ${String(secs).padStart(2, '0')}s`;
}

function currentTab() {
    return tabs.find((tab) => tab.id === state.tab) || tabs[0];
}

function houses() {
    return state.dashboard?.houses || [];
}

function selectedHouse() {
    const list = houses();
    if (!state.selectedHouseId && list.length > 0) {
        const ready = list.find((house) => house.unlocked && house.cooldown <= 0);
        state.selectedHouseId = (ready || list[0]).id;
    }

    return list.find((house) => Number(house.id) === Number(state.selectedHouseId)) || list[0] || null;
}

function toast(message, type = 'inform', title = 'ZeeKota House Robbery') {
    const id = `toast-${Date.now()}-${state.toastCount += 1}`;
    const node = document.createElement('div');
    node.className = `toast ${type}`;
    node.id = id;
    node.innerHTML = `<strong>${escapeHtml(title)}</strong><span>${escapeHtml(message)}</span>`;
    document.getElementById('toasts').appendChild(node);
    setTimeout(() => node.remove(), 4200);
}

function setPrompt(visible, key, message) {
    if (key) {
        promptKey.textContent = key;
    }

    if (message) {
        promptMessage.textContent = message;
    }

    screenPrompt.classList.toggle('is-visible', visible === true);
    screenPrompt.setAttribute('aria-hidden', visible === true ? 'false' : 'true');
}

function renderTabs() {
    tabsNode.innerHTML = tabs.map((tab) => `
        <button class="tab-button ${state.tab === tab.id ? 'active' : ''}" data-tab="${tab.id}">
            <span class="tab-icon">${tab.icon}</span>
            <span>${tab.label}</span>
        </button>
    `).join('');

    tabsNode.querySelectorAll('[data-tab]').forEach((button) => {
        button.addEventListener('click', () => {
            state.tab = button.dataset.tab;
            render();
        });
    });
}

function renderActiveStrip() {
    const active = state.dashboard?.active;
    const police = state.dashboard?.police;

    if (!active) {
        activeStrip.innerHTML = `
            <span class="pill"><strong>${police?.count ?? 0}/${police?.required ?? 0}</strong> police</span>
            <span class="pill">No active robbery</span>
        `;
        return;
    }

    activeStrip.innerHTML = `
        <span class="pill"><strong>${escapeHtml(active.houseLabel)}</strong> ${escapeHtml(active.stage)}</span>
        <span class="pill">Tier ${active.tier}</span>
        <span class="pill">${money(active.lootValue)} secured</span>
    `;
}

function levelPanel() {
    const stats = state.dashboard?.stats || {};
    const level = stats.levelData || {};
    return `
        <section class="panel progress-shell">
            <div class="contract-head">
                <div>
                    <p class="eyebrow">Operator level</p>
                    <h2>Level ${stats.currentLevel || 1}</h2>
                </div>
                <span class="pill"><strong>${Number(stats.totalXP || 0).toLocaleString()}</strong> XP</span>
            </div>
            <div class="progress-bar" style="--progress:${level.progress || 0}%"><span></span></div>
            <div class="progress-meta">
                <span>${Number(level.currentLevelXP || 0).toLocaleString()} XP in level</span>
                <span>${Number(level.xpForNextLevel || 0).toLocaleString()} to next</span>
            </div>
        </section>
    `;
}

function operationPanel() {
    const police = state.dashboard?.police || {};
    const selected = selectedHouse();
    const cooldown = selected ? selected.cooldown : 0;

    return `
        <section class="panel">
            <h2>Operation Status</h2>
            <div class="grid three">
                <div class="metric"><span>Police online</span><strong>${police.count || 0}/${police.required || 0}</strong></div>
                <div class="metric"><span>Cooldown</span><strong>${cooldown > 0 ? seconds(cooldown) : 'Ready'}</strong></div>
                <div class="metric"><span>Tier unlocked</span><strong>${highestTierUnlocked()}</strong></div>
            </div>
        </section>
    `;
}

function highestTierUnlocked() {
    const unlocked = houses().filter((house) => house.unlocked).map((house) => house.tier);
    return unlocked.length ? Math.max(...unlocked) : 0;
}

function statsCards() {
    const stats = state.dashboard?.stats || {};
    const cards = [
        ['Houses broken into', stats.housesBrokenInto],
        ['Successful robberies', stats.successfulRobberies],
        ['Failed robberies', stats.failedRobberies],
        ['Total loot value', money(stats.totalLootValue)],
        ['Best robbery value', money(stats.bestRobberyValue)],
        ['Current streak', stats.currentStreak],
        ['Failed lockpicks', stats.failedKeypadAttempts],
        ['Police alerts', stats.timesPoliceAlerted]
    ];

    return cards.map(([label, value]) => `
        <article class="stat-card">
            <span>${escapeHtml(label)}</span>
            <strong>${escapeHtml(value ?? 0)}</strong>
        </article>
    `).join('');
}

function contractCard(house, selectable = false) {
    const ready = house.unlocked && house.cooldown <= 0;
    const status = !house.unlocked ? house.lockedReason : (house.cooldown > 0 ? seconds(house.cooldown) : 'Ready');
    const statusClass = ready ? 'ready' : (!house.unlocked ? 'locked' : 'warn');

    return `
        <article class="contract-card ${Number(state.selectedHouseId) === Number(house.id) ? 'selected' : ''} ${!house.unlocked ? 'locked' : ''}" ${selectable ? `data-house="${house.id}"` : ''}>
            <div class="contract-head">
                <div>
                    <h3>${escapeHtml(house.label)}</h3>
                    <span class="muted small">${escapeHtml(house.description || '')}</span>
                </div>
                <span class="pill">Tier ${house.tier}</span>
            </div>
            <div class="meta-row">
                <span class="meta ${statusClass}">${escapeHtml(status)}</span>
                <span class="meta">Level ${house.requiredLevel}</span>
                <span class="meta">${house.lootCount} loot zones</span>
                <span class="meta">${house.dispatchAlertChance}% alert</span>
                ${house.requiredItem ? `<span class="meta">${escapeHtml(house.requiredItem)}</span>` : ''}
            </div>
        </article>
    `;
}

function renderDashboard() {
    const topContracts = houses().slice(0, 4).map((house) => contractCard(house, true)).join('');

    return `
        <div class="grid layout-two">
            <div class="grid">
                ${levelPanel()}
                ${operationPanel()}
                <section class="panel">
                    <h2>Available Contracts</h2>
                    <div class="contract-grid">${topContracts}</div>
                </section>
            </div>
            <section class="panel">
                <h2>Robbery Stats</h2>
                <div class="grid two">${statsCards()}</div>
            </section>
        </div>
    `;
}

function renderContracts() {
    const selected = selectedHouse();
    if (!selected) return '<div class="empty">No robbery contracts configured.</div>';

    const police = state.dashboard?.police || {};
    const active = state.dashboard?.active;
    const canStart = selected.unlocked && selected.cooldown <= 0 && police.enough && !active;

    return `
        <div class="grid layout-two">
            <section class="panel">
                <h2>House Contracts</h2>
                <div class="contract-grid">${houses().map((house) => contractCard(house, true)).join('')}</div>
            </section>
            <section class="panel">
                <h2>${escapeHtml(selected.label)}</h2>
                <p class="muted">${escapeHtml(selected.description || '')}</p>
                <div class="grid two">
                    <div class="metric"><span>Tier</span><strong>${selected.tier}</strong></div>
                    <div class="metric"><span>Required level</span><strong>${selected.requiredLevel}</strong></div>
                    <div class="metric"><span>Required police</span><strong>${police.count || 0}/${police.required || 0}</strong></div>
                    <div class="metric"><span>Cooldown</span><strong>${selected.cooldown > 0 ? seconds(selected.cooldown) : 'Ready'}</strong></div>
                </div>
                <div class="button-row">
                    <button id="startBtn" class="btn primary" ${canStart ? '' : 'disabled'}>Start Robbery</button>
                    <button id="cancelBtn" class="btn danger" ${active ? '' : 'disabled'}>Cancel Active Robbery</button>
                </div>
            </section>
        </div>
    `;
}

function renderProgression() {
    const level = state.dashboard?.stats?.currentLevel || 1;
    const tiers = [1, 2, 3, 4, 5].map((tier) => {
        const house = houses().find((item) => item.tier === tier);
        const requiredLevel = house?.requiredLevel || state.dashboard?.config?.progression?.levelRequiredByTier?.[tier] || 1;
        const unlocked = level >= requiredLevel;
        return `
            <article class="tier-card">
                <div class="tier-badge">${tier}</div>
                <div>
                    <h3>Tier ${tier}</h3>
                    <span class="muted small">${house ? escapeHtml(house.label) : 'Configurable tier'}</span>
                </div>
                <span class="meta ${unlocked ? 'ready' : 'locked'}">${unlocked ? 'Unlocked' : `Level ${requiredLevel}`}</span>
            </article>
        `;
    }).join('');

    return `
        <div class="grid">
            ${levelPanel()}
            <section class="panel">
                <h2>Tier Access</h2>
                <div class="tier-list">${tiers}</div>
            </section>
        </div>
    `;
}

function renderStats() {
    return `
        <section class="panel">
            <h2>Persistent Stats</h2>
            <div class="grid four">${statsCards()}</div>
        </section>
    `;
}

function renderActive() {
    const active = state.dashboard?.active;
    if (!active) {
        return '<div class="empty">No active robbery.</div>';
    }

    return `
        <section class="panel">
            <h2>${escapeHtml(active.houseLabel)}</h2>
            <div class="grid four">
                <div class="stat-card"><span>Stage</span><strong>${escapeHtml(active.stage)}</strong></div>
                <div class="stat-card"><span>Tier</span><strong>${active.tier}</strong></div>
                <div class="stat-card"><span>Searched</span><strong>${active.searched}</strong></div>
                <div class="stat-card"><span>Loot value</span><strong>${money(active.lootValue)}</strong></div>
            </div>
            <div class="button-row">
                <button id="cancelBtn" class="btn danger">Cancel Active Robbery</button>
            </div>
        </section>
    `;
}

function renderContent() {
    if (!state.dashboard) return '<div class="empty">Loading dashboard.</div>';

    if (state.tab === 'contracts') return renderContracts();
    if (state.tab === 'progression') return renderProgression();
    if (state.tab === 'stats') return renderStats();
    if (state.tab === 'active') return renderActive();
    return renderDashboard();
}

function wireContent() {
    content.querySelectorAll('[data-house]').forEach((card) => {
        card.addEventListener('click', () => {
            state.selectedHouseId = Number(card.dataset.house);
            if (state.tab === 'dashboard') state.tab = 'contracts';
            render();
        });
    });

    const startBtn = document.getElementById('startBtn');
    if (startBtn) {
        startBtn.addEventListener('click', async () => {
            const house = selectedHouse();
            if (!house) return;
            const result = await post('startRobbery', { houseId: house.id });
            if (!result.ok) {
                toast('Contract could not be started.', 'error');
            }
        });
    }

    const cancelBtn = document.getElementById('cancelBtn');
    if (cancelBtn) {
        cancelBtn.addEventListener('click', async () => {
            const result = await post('cancelRobbery');
            if (result.ok) {
                if (!applyDashboard(result.result?.dashboard) && state.dashboard) {
                    state.dashboard.active = null;
                }
                toast('Active robbery cancelled.', 'warning');
                render();
            }
        });
    }
}

function render() {
    renderTabs();
    renderActiveStrip();
    viewTitle.textContent = currentTab().label;
    content.innerHTML = renderContent();
    wireContent();
}

function applyDashboard(dashboard) {
    if (!dashboard || !dashboard.ok) {
        return false;
    }

    state.dashboard = dashboard;
    selectedHouse();

    if (state.visible) {
        render();
    }

    return true;
}

async function refreshDashboard() {
    const result = await post('refreshDashboard');
    applyDashboard(result);
}

function openDashboard(payload) {
    state.visible = true;
    state.dashboard = payload;
    app.classList.remove('hidden');
    app.setAttribute('aria-hidden', 'false');
    selectedHouse();
    render();
}

function closeDashboard() {
    state.visible = false;
    app.classList.add('hidden');
    app.setAttribute('aria-hidden', 'true');
}

function randomDigit() {
    return String(Math.floor(Math.random() * 10));
}

function renderSequence() {
    const mini = state.minigame;
    sequenceNode.innerHTML = mini.sequence.map((digit, index) => `
        <span class="seq-cell ${index < mini.input.length ? 'done' : ''} ${index === mini.input.length ? 'current' : ''}">${escapeHtml(digit)}</span>
    `).join('');
}

function makeKeys() {
    const mini = state.minigame;
    const keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'];
    for (let index = 0; index < mini.failTiles; index += 1) {
        keys.push('!');
    }
    keys.sort(() => Math.random() - 0.5);
    return keys;
}

function renderKeypad() {
    const keys = makeKeys();
    keypadGrid.innerHTML = keys.map((key) => `
        <button class="key ${key === '!' ? 'fail' : ''}" data-key="${key}">${key}</button>
    `).join('');

    keypadGrid.querySelectorAll('[data-key]').forEach((button) => {
        button.addEventListener('click', () => handleKey(button.dataset.key));
    });
}

function newSequence() {
    const mini = state.minigame;
    mini.sequence = Array.from({ length: mini.sequenceLength }, randomDigit);
    mini.input = [];
    miniReadout.textContent = 'Match the sequence';
    miniAttempt.textContent = `Attempt ${mini.successes + 1}/${mini.attemptsRequired}`;
    renderSequence();
    renderKeypad();
}

function finishMinigame(success) {
    if (!state.minigame) return;

    clearInterval(state.minigame.timer);
    state.minigame = null;
    minigameNode.classList.add('hidden');
    post('minigameResult', { success });
}

function handleKey(key) {
    const mini = state.minigame;
    if (!mini) return;

    if (key === '!') {
        miniReadout.textContent = 'Trap tile hit';
        finishMinigame(false);
        return;
    }

    const expected = mini.sequence[mini.input.length];
    if (key !== expected) {
        miniReadout.textContent = 'Sequence mismatch';
        finishMinigame(false);
        return;
    }

    mini.input.push(key);
    renderSequence();

    if (mini.input.length >= mini.sequence.length) {
        mini.successes += 1;
        if (mini.successes >= mini.attemptsRequired) {
            miniReadout.textContent = 'Bypass accepted';
            finishMinigame(true);
        } else {
            setTimeout(newSequence, 280);
        }
    }
}

function startMinigame(data) {
    const difficulty = data.difficulty || {};
    const duration = Number(difficulty.duration || 15000);
    const started = Date.now();

    state.minigame = {
        sequenceLength: Number(difficulty.sequenceLength || 4),
        failTiles: Number(difficulty.failTiles || 2),
        attemptsRequired: Number(difficulty.attemptsRequired || 1),
        successes: 0,
        input: [],
        sequence: [],
        timer: null
    };

    miniTier.textContent = `Tier ${data.tier || 1}`;
    minigameNode.classList.remove('hidden');
    timerBar.style.transform = 'scaleX(1)';
    newSequence();

    state.minigame.timer = setInterval(() => {
        const elapsed = Date.now() - started;
        const ratio = Math.max(0, 1 - (elapsed / duration));
        timerBar.style.transform = `scaleX(${ratio})`;
        if (ratio <= 0) {
            miniReadout.textContent = 'Bypass timed out';
            finishMinigame(false);
        }
    }, 50);
}

closeBtn.addEventListener('click', () => post('close'));

window.addEventListener('keydown', (event) => {
    if (state.minigame && /^[0-9]$/.test(event.key)) {
        handleKey(event.key);
        return;
    }

    if (event.key === 'Escape') {
        if (state.minigame) {
            finishMinigame(false);
        } else if (state.visible) {
            post('close');
        }
    }
});

window.addEventListener('message', (event) => {
    const data = event.data || {};

    if (data.action === 'openDashboard') {
        openDashboard(data.payload);
    } else if (data.action === 'closeDashboard') {
        closeDashboard();
    } else if (data.action === 'startMinigame') {
        startMinigame(data);
    } else if (data.action === 'toast') {
        toast(data.message || '', data.type || 'inform', data.title || 'ZeeKota House Robbery');
    } else if (data.action === 'prompt') {
        setPrompt(data.visible, data.key, data.message);
    } else if (data.action === 'lootResult') {
        const rewards = data.payload?.rewards || [];
        const label = rewards.length ? rewards.map((item) => `${item.amount} ${item.item}`).join(', ') : 'Nothing found';
        toast(label, rewards.length ? 'success' : 'inform', 'Loot Search');
    } else if (data.action === 'robberyComplete') {
        const payload = data.payload || {};
        toast(`XP ${payload.xp || 0} | Loot ${money(payload.lootValue || 0)}`, payload.success ? 'success' : 'warning', 'Robbery Finished');
        if (!applyDashboard(payload.dashboard)) {
            refreshDashboard();
        }
    } else if (data.action === 'robberyCancelled') {
        toast('Active robbery cancelled.', 'warning');
        refreshDashboard();
    } else if (data.action === 'robberyState') {
        toast(`${data.payload?.houseLabel || 'House'} active.`, 'success');
    }
});
