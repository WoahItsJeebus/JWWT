const API_BASE = "https://wutheringwaves.fandom.com/api.php";
const CATEGORY = "Category:Resonators";

const grid = document.getElementById("grid");

let ownedState = JSON.parse(localStorage.getItem("ww_resonators_owned")) || {};

async function fetchAllResonators() {
    let members = [];
    let cmcontinue = null;

    do {
        let url = `${API_BASE}?action=query&list=categorymembers&cmtitle=${encodeURIComponent(CATEGORY)}&cmlimit=500&format=json&origin=*`;

        if (cmcontinue) {
            url += `&cmcontinue=${encodeURIComponent(cmcontinue)}`;
        }

        const res = await fetch(url);
        const data = await res.json();

        members = members.concat(data.query.categorymembers);

        cmcontinue = data.continue ? data.continue.cmcontinue : null;

    } while (cmcontinue);

    return members;
}

async function fetchThumbnail(title) {
    const url = `${API_BASE}?action=query&titles=${encodeURIComponent(title)}&prop=pageimages&format=json&pithumbsize=200&origin=*`;
    const res = await fetch(url);
    const data = await res.json();

    const pages = data.query.pages;
    const page = Object.values(pages)[0];

    return page.thumbnail ? page.thumbnail.source : null;
}

function saveState() {
    localStorage.setItem("ww_resonators_owned", JSON.stringify(ownedState));
}

function createCard(title, imageUrl) {
    const card = document.createElement("div");
    card.classList.add("card");

    const img = document.createElement("img");
    img.src = imageUrl;
    img.alt = title;

    card.appendChild(img);

    const isOwned = ownedState[title];

    card.classList.add(isOwned ? "owned" : "unowned");

    card.addEventListener("click", () => {
        ownedState[title] = !ownedState[title];
        card.classList.toggle("owned");
        card.classList.toggle("unowned");
        saveState();
    });

    grid.appendChild(card);
}

async function init() {
    const members = await fetchAllResonators();

    // Filter out non-main pages
    const validMembers = members.filter(m => m.ns === 0);

    for (const member of validMembers) {
        const thumb = await fetchThumbnail(member.title);
        if (thumb) {
            createCard(member.title, thumb);
        }
    }
}

init();