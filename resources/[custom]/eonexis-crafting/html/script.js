'use strict';
let inventory = {};

window.addEventListener('message', e => {
    const d = e.data;
    if (d.action === 'open') {
        inventory = d.inventory || {};
        renderRecipes(d.recipes);
        document.getElementById('app').classList.remove('hidden');
    } else if (d.action === 'close') {
        document.getElementById('app').classList.add('hidden');
    }
});

function canCraft(recipe) {
    return recipe.ingredients.every(ing => (inventory[ing.item] || 0) >= ing.qty);
}

function renderRecipes(recipes) {
    const container = document.getElementById('recipes');
    container.innerHTML = '';
    if (!recipes || !recipes.length) {
        container.innerHTML = '<p style="color:#666;text-align:center;padding:20px;">No recipes available.</p>';
        return;
    }
    recipes.forEach(r => {
        const ok = canCraft(r);
        const card = document.createElement('div');
        card.className = 'recipe-card ' + (ok ? 'can-craft' : 'cannot-craft');

        const ings = r.ingredients.map(ing => {
            const have = inventory[ing.item] || 0;
            return `${ing.item} ${have}/${ing.qty}`;
        }).join(', ');

        card.innerHTML = `
          <div class="recipe-info">
            <div class="recipe-name">${r.icon || ''} ${r.label}</div>
            <div class="recipe-ing">Needs: ${ings}</div>
            <div class="recipe-time">⏱ ${r.time}s → ${r.result.qty}x ${r.result.item}</div>
          </div>
          <button class="craft-btn ${ok ? 'active' : 'inactive'}"
            onclick="${ok ? `doCraft('${r.id}')` : ''}">${ok ? 'Craft' : 'Missing'}</button>
        `;
        container.appendChild(card);
    });
}

function doCraft(recipeId) {
    fetch(`https://eonexis-crafting/craft`, {
        method: 'POST',
        body: JSON.stringify({ recipeId })
    });
}

function closeNUI() {
    fetch(`https://eonexis-crafting/close`, {
        method: 'POST',
        body: JSON.stringify({})
    });
}

// UI scale from eonexis-settings
window.addEventListener('message', function(e) {
    if (e.data && e.data.action === 'setScale') {
        document.body.style.transform = 'scale(' + e.data.scale + ')';
        document.body.style.transformOrigin = 'center center';
    }
});
