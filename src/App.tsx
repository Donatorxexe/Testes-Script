import { useState, useEffect, useCallback, useRef } from 'react';
import scriptRaw from '../Medusa.lua?raw';

// ═══════════════════════════════════════════════════════
// MEDUSA v13 ARCHITECT — Premium Web Showcase
// Made by .donatorexe. | Xeno Optimized
// ═══════════════════════════════════════════════════════

// ─── TYPES ─────────────────────────────────────────────
interface Feature {
  icon: string;
  name: string;
  desc: string;
  tag?: string;
  tagColor?: string;
}

interface TabData {
  id: string;
  icon: string;
  label: string;
  features: Feature[];
}

interface ThemePreset {
  name: string;
  colors: string[];
  accent: string;
}

// ─── DATA ──────────────────────────────────────────────
const TABS: TabData[] = [
  {
    id: 'status', icon: '📊', label: 'Status',
    features: [
      { icon: '🟢', name: 'Live Status Pills', desc: 'ESP, Aimbot, Fly, Noclip, Silent Aim, Trigger Bot — todos com indicador ON/OFF em tempo real', tag: 'CORE', tagColor: '#22c55e' },
      { icon: '🎯', name: 'Target Lock Card', desc: 'Mostra nome, HP bar, distância e parte do corpo do alvo atual quando o aimbot está ativo', tag: 'HUD', tagColor: '#a855f7' },
      { icon: '☠️', name: 'Kill Feed', desc: 'Log das últimas 6 kills com timestamp HH:MM:SS e nome do jogador eliminado', tag: 'LOG', tagColor: '#ef4444' },
      { icon: '📡', name: 'FPS & Ping Monitor', desc: 'FPS e ping atualizados em tempo real na topbar e watermark', tag: 'INFO', tagColor: '#3b82f6' },
      { icon: '🔒', name: 'StreamProof Status', desc: 'Indicador visual do método de proteção ativo e compatibilidade do executor', tag: 'SP', tagColor: '#f59e0b' },
      { icon: '🔄', name: 'ESP Auto-Refresh Timer', desc: 'Countdown para o próximo refresh automático do ESP com barra de progresso', tag: 'ESP', tagColor: '#06b6d4' },
    ]
  },
  {
    id: 'aimbot', icon: '🎯', label: 'Aimbot',
    features: [
      { icon: '🎯', name: 'Aimbot Normal', desc: 'Lock no alvo com RMB. Smooth ajustável 0 (snap) a 100 (legit). FOV circle visual', tag: 'AIM', tagColor: '#a855f7' },
      { icon: '🔇', name: 'Silent Aim', desc: 'Redireciona mouse.Hit e mouse.Target via hookmetamethod sem mover a câmara', tag: 'SILENT', tagColor: '#ec4899' },
      { icon: '🔫', name: 'Trigger Bot', desc: 'Dispara automaticamente quando a mira está sobre um inimigo. Delay e FOV configuráveis', tag: 'AUTO', tagColor: '#ef4444' },
      { icon: '🧠', name: 'Prediction', desc: 'Previsão de movimento do alvo baseada em velocidade. Compensa o delay de rede', tag: 'NEW', tagColor: '#f59e0b' },
      { icon: '🎲', name: 'Hit Part Selection', desc: 'Escolhe Head, Torso, Random ou Closest. Random alterna entre partes a cada tick', tag: 'NEW', tagColor: '#f59e0b' },
      { icon: '📏', name: 'Max Distance', desc: 'Slider 50-2000 studs — ignora alvos fora da distância configurada', tag: 'CFG', tagColor: '#06b6d4' },
      { icon: '👥', name: 'Team Check', desc: 'Ignora jogadores da mesma equipa automaticamente', tag: 'CHECK', tagColor: '#22c55e' },
      { icon: '👁️', name: 'Visible Check', desc: 'Raycast check — só mira em alvos sem paredes à frente', tag: 'CHECK', tagColor: '#22c55e' },
      { icon: '❤️', name: 'Health Check', desc: 'Só mira em alvos com HP acima do mínimo definido (slider 1-100%)', tag: 'CHECK', tagColor: '#22c55e' },
      { icon: '🔄', name: 'FOV & Smooth', desc: 'FOV radius 50-500px. Smooth 0=snap instantâneo, 100=movimento suave legit', tag: 'CFG', tagColor: '#06b6d4' },
    ]
  },
  {
    id: 'visuals', icon: '👁️', label: 'Visuals',
    features: [
      { icon: '✨', name: 'ESP Highlights', desc: 'Highlight nos jogadores com cor accent. Inclui nome, distância e HP bar', tag: 'ESP', tagColor: '#06b6d4' },
      { icon: '📦', name: 'ESP 3D Boxes', desc: 'Caixas 3D ao redor dos jogadores usando BoxHandleAdornment — 100% Instance.new', tag: 'NEW', tagColor: '#f59e0b' },
      { icon: '📐', name: 'Tracers', desc: 'Linhas do fundo do ecrã até cada jogador usando Frame rotacionados', tag: 'NEW', tagColor: '#f59e0b' },
      { icon: '💀', name: 'Skeleton ESP', desc: 'Linhas de beam conectando as partes do corpo — visualiza o esqueleto dos jogadores', tag: 'NEW', tagColor: '#f59e0b' },
      { icon: '➕', name: 'Crosshair', desc: '4 estilos: Cross, Dot, Circle, T-Cross. Tamanho e gap ajustáveis', tag: 'HUD', tagColor: '#a855f7' },
      { icon: '💡', name: 'Fullbright', desc: 'Remove escuridão, fog e sombras. Restaura ao desativar', tag: 'WORLD', tagColor: '#3b82f6' },
      { icon: '📏', name: 'ESP Distance Filter', desc: 'Slider para limitar a distância máxima do ESP (50-5000 studs)', tag: 'CFG', tagColor: '#06b6d4' },
      { icon: '🌈', name: 'Rainbow ESP', desc: 'Cor do ESP muda dinamicamente com o sistema RGB', tag: 'RGB', tagColor: '#ec4899' },
    ]
  },
  {
    id: 'movement', icon: '🏃', label: 'Movement',
    features: [
      { icon: '✈️', name: 'Fly', desc: 'Voa em qualquer direção com WASD + Space/Ctrl. Velocidade ajustável 50-300', tag: 'MOVE', tagColor: '#3b82f6' },
      { icon: '👻', name: 'Noclip', desc: 'Atravessa paredes e objetos sólidos. Re-aplica automaticamente no respawn', tag: 'MOVE', tagColor: '#3b82f6' },
      { icon: '🏃', name: 'Speed Hack', desc: 'WalkSpeed ajustável 16-200. Re-aplica no respawn automaticamente', tag: 'MOVE', tagColor: '#3b82f6' },
      { icon: '🦘', name: 'Infinite Jump', desc: 'Pula infinitamente no ar sem limite de saltos', tag: 'MOVE', tagColor: '#3b82f6' },
      { icon: '🌀', name: 'Spin Bot', desc: 'Rotação visual contínua do personagem — os outros veem-te a rodar', tag: 'NEW', tagColor: '#f59e0b' },
      { icon: '⚡', name: 'Speed Bypass', desc: 'Alternância rápida de velocidade para contornar anti-cheats básicos', tag: 'NEW', tagColor: '#f59e0b' },
      { icon: '🪂', name: 'No Fall Damage', desc: 'Cancela ragdoll e fall damage. Desativa FallingDown state', tag: 'SAFE', tagColor: '#22c55e' },
      { icon: '🖱️', name: 'Click TP', desc: 'Segura B + clica para teleportar ao cursor instantaneamente', tag: 'TP', tagColor: '#a855f7' },
    ]
  },
  {
    id: 'combat', icon: '⚔️', label: 'Combat',
    features: [
      { icon: '📦', name: 'Hitbox Expander', desc: 'Aumenta hitboxes dos inimigos de 1x a 25x. Transparência ajustável', tag: 'HIT', tagColor: '#ef4444' },
      { icon: '🎯', name: 'Trigger FOV', desc: 'Raio em pixels para o Trigger Bot ativar o disparo (5-100px)', tag: 'CFG', tagColor: '#06b6d4' },
      { icon: '⏱️', name: 'Trigger Delay', desc: 'Delay entre disparos automáticos do Trigger Bot (0.01s - 1s)', tag: 'CFG', tagColor: '#06b6d4' },
      { icon: '👁️', name: 'Hitbox Transparency', desc: 'Controla a transparência visual das hitboxes expandidas (0-100%)', tag: 'CFG', tagColor: '#06b6d4' },
      { icon: '☠️', name: 'Kill Detection', desc: 'Deteta quando o Trigger Bot elimina um alvo e adiciona ao Kill Feed', tag: 'LOG', tagColor: '#a855f7' },
    ]
  },
  {
    id: 'players', icon: '👥', label: 'Players',
    features: [
      { icon: '📋', name: 'Player List', desc: 'Lista todos os jogadores com DisplayName, @Username e barra de HP colorida', tag: 'LIST', tagColor: '#06b6d4' },
      { icon: '📷', name: 'Spectate', desc: 'Troca câmara para ver pela perspetiva de outro jogador. Unspectate para voltar', tag: 'VIEW', tagColor: '#3b82f6' },
      { icon: '💥', name: 'Fling', desc: 'Atira o jogador com BodyVelocity + AngularVelocity massivos', tag: 'FORCE', tagColor: '#ef4444' },
      { icon: '🏃', name: 'Teleport To', desc: 'Teleporta 3 studs atrás do jogador selecionado instantaneamente', tag: 'TP', tagColor: '#a855f7' },
      { icon: '🔄', name: 'Auto-Refresh', desc: 'Lista atualiza automaticamente a cada 5 segundos quando na tab', tag: 'AUTO', tagColor: '#22c55e' },
    ]
  },
  {
    id: 'themes', icon: '🎨', label: 'Themes',
    features: [
      { icon: '🌈', name: 'RGB Engine', desc: 'Animação RGB aplicável separadamente ao Stroke, Título e Tab Indicator', tag: 'RGB', tagColor: '#ec4899' },
      { icon: '⚡', name: 'RGB Speed', desc: 'Slider para controlar a velocidade da animação RGB (1-10)', tag: 'RGB', tagColor: '#ec4899' },
      { icon: '🎨', name: 'RGB Saturation', desc: 'Slider para ajustar a saturação da cor RGB (0-100%)', tag: 'RGB', tagColor: '#ec4899' },
      { icon: '💡', name: 'RGB Brightness', desc: 'Slider para ajustar o brilho da cor RGB (0-100%)', tag: 'RGB', tagColor: '#ec4899' },
      { icon: '🎭', name: 'Vaporwave Theme', desc: 'Rosa + Cyan + Roxo — estética retro anos 80', tag: 'THEME', tagColor: '#ec4899' },
      { icon: '🌙', name: 'Midnight Theme', desc: 'Azul escuro + Prata — elegante e discreto', tag: 'THEME', tagColor: '#3b82f6' },
      { icon: '☢️', name: 'Toxic Green Theme', desc: 'Verde neon + Preto — visual de hacker', tag: 'THEME', tagColor: '#22c55e' },
      { icon: '🩸', name: 'Blood Red Theme', desc: 'Vermelho escuro + Preto — agressivo e intimidante', tag: 'THEME', tagColor: '#ef4444' },
      { icon: '👑', name: 'Gold Luxury Theme', desc: 'Dourado + Preto — premium e sofisticado', tag: 'THEME', tagColor: '#f59e0b' },
      { icon: '🐍', name: 'Medusa Default', desc: 'Teal + Dark — o tema original do Medusa', tag: 'THEME', tagColor: '#00d4aa' },
      { icon: '❄️', name: 'Frost Theme', desc: 'Azul gelo + Branco — clean e gelado', tag: 'THEME', tagColor: '#06b6d4' },
      { icon: '🔥', name: 'Inferno Theme', desc: 'Laranja + Vermelho — quente e intenso', tag: 'THEME', tagColor: '#f97316' },
    ]
  },
  {
    id: 'gui', icon: '🖥️', label: 'GUI Editor',
    features: [
      { icon: '📐', name: 'Corner Radius', desc: 'Slider 0 (retangular) a 20 (arredondado) — muda todos os cantos da interface', tag: 'SHAPE', tagColor: '#a855f7' },
      { icon: '👁️', name: 'Background Transparency', desc: 'Slider 0% (sólido) a 90% (quase invisível) — controla opacidade do painel', tag: 'ALPHA', tagColor: '#06b6d4' },
      { icon: '🔘', name: 'Toggle Style: Dot', desc: 'Círculo pequeno que desliza dentro do toggle — minimalista', tag: 'STYLE', tagColor: '#22c55e' },
      { icon: '✅', name: 'Toggle Style: Check', desc: 'Checkmark ✓ aparece quando ativo — clássico', tag: 'STYLE', tagColor: '#22c55e' },
      { icon: '🟢', name: 'Toggle Style: Fill', desc: 'Todo o toggle muda de cor — preenchimento total', tag: 'STYLE', tagColor: '#22c55e' },
      { icon: '⚡', name: 'Toggle Style: Slash', desc: 'Linha diagonal quando desativado, reta quando ativo', tag: 'STYLE', tagColor: '#22c55e' },
      { icon: '▬', name: 'Slider Style: Bar', desc: 'Barra padrão com fill e knob redondo', tag: 'STYLE', tagColor: '#3b82f6' },
      { icon: '─', name: 'Slider Style: Thin', desc: 'Linha fina 4px com knob pequeno — elegante', tag: 'STYLE', tagColor: '#3b82f6' },
      { icon: '█', name: 'Slider Style: Thick', desc: 'Barra grossa 16px sem knob visível — moderno', tag: 'STYLE', tagColor: '#3b82f6' },
      { icon: '✨', name: 'Slider Style: Glow', desc: 'Barra com efeito de brilho e knob com glow — premium', tag: 'STYLE', tagColor: '#3b82f6' },
      { icon: '📏', name: 'Panel Width/Height', desc: 'Redimensiona o painel principal (320-600 × 480-900)', tag: 'SIZE', tagColor: '#f59e0b' },
      { icon: '🔤', name: 'Font & Title Size', desc: 'Ajusta tamanho de texto e título independentemente', tag: 'TYPO', tagColor: '#f59e0b' },
      { icon: '📐', name: 'Card Spacing & Padding', desc: 'Controla espaço entre e dentro dos cards', tag: 'LAYOUT', tagColor: '#f59e0b' },
      { icon: '💾', name: 'Save/Load Config', desc: 'Guarda todas as configurações visuais e carrega automaticamente ao reiniciar', tag: 'DATA', tagColor: '#22c55e' },
    ]
  },
  {
    id: 'binds', icon: '🎮', label: 'Binds',
    features: [
      { icon: '🎯', name: 'Aimbot — G', desc: 'Toggle aimbot normal' },
      { icon: '🔇', name: 'Silent Aim — J', desc: 'Toggle silent aim' },
      { icon: '🔫', name: 'Trigger Bot — K', desc: 'Toggle trigger bot' },
      { icon: '👁️', name: 'ESP — T', desc: 'Toggle ESP highlights' },
      { icon: '✈️', name: 'Fly — F', desc: 'Toggle fly mode' },
      { icon: '👻', name: 'Noclip — U', desc: 'Toggle noclip' },
      { icon: '📦', name: 'Hitbox — H', desc: 'Toggle hitbox expander' },
      { icon: '🏃', name: 'Speed — M', desc: 'Toggle speed hack' },
      { icon: '🦘', name: 'Inf Jump — N', desc: 'Toggle infinite jump' },
      { icon: '🌀', name: 'Spin Bot — Z', desc: 'Toggle spin bot visual' },
      { icon: '💡', name: 'Fullbright — L', desc: 'Toggle fullbright' },
      { icon: '➕', name: 'Crosshair — C', desc: 'Toggle crosshair overlay' },
      { icon: '🖱️', name: 'Click TP — B+Click', desc: 'Hold B + click to teleport' },
      { icon: '🪂', name: 'No Fall Dmg — V', desc: 'Toggle no fall damage' },
      { icon: '🔒', name: 'Ghost Mode — F2', desc: 'Toggle ghost/stream proof' },
      { icon: '🐍', name: 'Toggle GUI — Y', desc: 'Show/hide the Medusa panel' },
      { icon: '🚨', name: 'Panic — End', desc: 'Desativa TUDO de uma vez' },
      { icon: '💀', name: 'Eject — P', desc: 'Remove o script completamente' },
    ]
  },
  {
    id: 'misc', icon: '🔧', label: 'Misc',
    features: [
      { icon: '🛡️', name: 'Anti-AFK', desc: 'Nunca mais kick por estar idle — VirtualUser automático', tag: 'SAFE', tagColor: '#22c55e' },
      { icon: '👻', name: 'Ghost Mode', desc: 'Alternativa ao StreamProof: painel fica 95% transparente, aparece ao hover', tag: 'SP', tagColor: '#f59e0b' },
      { icon: '🔒', name: 'StreamProof', desc: '5 métodos fallback: gethui → get_hidden_gui → protect_gui+CoreGui → cloneref → CoreGui', tag: 'SP', tagColor: '#f59e0b' },
      { icon: '🔁', name: 'Rejoin', desc: 'Reconecta ao mesmo servidor via TeleportService', tag: 'SERVER', tagColor: '#3b82f6' },
      { icon: '🌐', name: 'Server Hop', desc: 'Busca servidor alternativo via API Roblox e teleporta', tag: 'SERVER', tagColor: '#3b82f6' },
      { icon: '📋', name: 'Copy Game Link', desc: 'Copia o link do jogo para o clipboard', tag: 'UTIL', tagColor: '#06b6d4' },
      { icon: '🔄', name: 'Refresh ESP', desc: 'Força refresh de todos os highlights e billboards do ESP', tag: 'ACTION', tagColor: '#a855f7' },
      { icon: '🚨', name: 'Panic Key (End)', desc: 'Desativa TODAS as funções de uma vez — seguro para emergências', tag: 'DANGER', tagColor: '#ef4444' },
      { icon: '💀', name: 'Eject (P)', desc: 'Remove o script completamente, restaura lighting e destroi GUIs', tag: 'DANGER', tagColor: '#ef4444' },
      { icon: '🐍', name: 'Watermark Draggável', desc: 'HUD com MEDUSA v13 | FPS | Ping — arrasta para qualquer posição', tag: 'HUD', tagColor: '#a855f7' },
      { icon: '💾', name: 'Config System', desc: 'Salva/carrega todas as configurações automaticamente via writefile', tag: 'DATA', tagColor: '#22c55e' },
    ]
  },
];

const THEME_PRESETS: ThemePreset[] = [
  { name: '🐍 Medusa', colors: ['#00d4aa', '#0d0d15', '#12121c'], accent: '#00d4aa' },
  { name: '🎭 Vaporwave', colors: ['#ff71ce', '#01cdfe', '#b967ff'], accent: '#ff71ce' },
  { name: '🌙 Midnight', colors: ['#4c6ef5', '#1a1b3a', '#252660'], accent: '#4c6ef5' },
  { name: '☢️ Toxic', colors: ['#39ff14', '#0a0f0a', '#0d1a0d'], accent: '#39ff14' },
  { name: '🩸 Blood', colors: ['#dc2626', '#1a0808', '#2d0a0a'], accent: '#dc2626' },
  { name: '👑 Gold', colors: ['#fbbf24', '#1a1508', '#2d220d'], accent: '#fbbf24' },
  { name: '❄️ Frost', colors: ['#67e8f9', '#081318', '#0d1f26'], accent: '#67e8f9' },
  { name: '🔥 Inferno', colors: ['#f97316', '#1a0f08', '#2d1a0d'], accent: '#f97316' },
];

const TOGGLE_STYLES = [
  { name: 'Dot', icon: '🔘', desc: 'Círculo deslizante minimalista' },
  { name: 'Check', icon: '✅', desc: 'Checkmark clássico' },
  { name: 'Fill', icon: '🟢', desc: 'Preenchimento total' },
  { name: 'Slash', icon: '⚡', desc: 'Linha diagonal/reta' },
];

const SLIDER_STYLES = [
  { name: 'Bar', icon: '▬', desc: 'Barra padrão com knob' },
  { name: 'Thin', icon: '─', desc: 'Linha fina elegante' },
  { name: 'Thick', icon: '█', desc: 'Barra grossa sem knob' },
  { name: 'Glow', icon: '✨', desc: 'Barra com efeito glow' },
];

const STATS = [
  { value: '30+', label: 'Features', icon: '⚡' },
  { value: '10', label: 'Tabs', icon: '📑' },
  { value: '18', label: 'Keybinds', icon: '🎮' },
  { value: '8', label: 'Themes', icon: '🎨' },
  { value: '4+4', label: 'UI Styles', icon: '🖥️' },
  { value: 'v13', label: 'Version', icon: '🐍' },
];

// ─── COMPONENTS ────────────────────────────────────────

function CopyButton({ text, label }: { text: string; label: string }) {
  const [copied, setCopied] = useState(false);
  const handleCopy = useCallback(() => {
    navigator.clipboard.writeText(text).then(() => {
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    });
  }, [text]);

  return (
    <button
      onClick={handleCopy}
      style={{
        padding: '12px 24px',
        background: copied ? '#22c55e' : '#00d4aa',
        color: '#000',
        border: 'none',
        borderRadius: '8px',
        fontWeight: 700,
        fontSize: '14px',
        cursor: 'pointer',
        transition: 'all 0.3s ease',
        transform: copied ? 'scale(0.95)' : 'scale(1)',
        fontFamily: 'inherit',
        display: 'flex',
        alignItems: 'center',
        gap: '8px',
      }}
    >
      {copied ? '✅ Copiado!' : `📋 ${label}`}
    </button>
  );
}

function FeatureCard({ f, index }: { f: Feature; index: number }) {
  const [hovered, setHovered] = useState(false);

  return (
    <div
      className={`fade-up delay-${Math.min(index % 6 + 1, 6)}`}
      onMouseEnter={() => setHovered(true)}
      onMouseLeave={() => setHovered(false)}
      style={{
        background: hovered ? 'rgba(24, 24, 38, 0.95)' : 'rgba(18, 18, 28, 0.8)',
        border: `1px solid ${hovered ? '#00d4aa40' : '#1e1e3020'}`,
        borderRadius: '10px',
        padding: '16px',
        transition: 'all 0.3s ease',
        transform: hovered ? 'translateY(-2px)' : 'translateY(0)',
        boxShadow: hovered ? '0 8px 24px rgba(0, 212, 170, 0.08)' : 'none',
        display: 'flex',
        gap: '12px',
        alignItems: 'flex-start',
      }}
    >
      <span style={{ fontSize: '20px', lineHeight: 1, flexShrink: 0, marginTop: '2px' }}>{f.icon}</span>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '8px', flexWrap: 'wrap' }}>
          <span style={{ fontWeight: 700, fontSize: '13px', color: '#e4e4e7' }}>{f.name}</span>
          {f.tag && (
            <span style={{
              fontSize: '9px',
              fontWeight: 800,
              padding: '2px 6px',
              borderRadius: '4px',
              background: `${f.tagColor}20`,
              color: f.tagColor,
              border: `1px solid ${f.tagColor}30`,
              letterSpacing: '0.5px',
            }}>
              {f.tag}
            </span>
          )}
        </div>
        <p style={{ fontSize: '11px', color: '#71717a', marginTop: '4px', lineHeight: 1.5 }}>{f.desc}</p>
      </div>
    </div>
  );
}

function TabButton({ tab, active, onClick }: { tab: TabData; active: boolean; onClick: () => void }) {
  const [hovered, setHovered] = useState(false);
  return (
    <button
      onClick={onClick}
      onMouseEnter={() => setHovered(true)}
      onMouseLeave={() => setHovered(false)}
      style={{
        padding: '8px 16px',
        background: active ? '#00d4aa18' : hovered ? '#ffffff08' : 'transparent',
        border: `1px solid ${active ? '#00d4aa40' : 'transparent'}`,
        borderRadius: '8px',
        color: active ? '#00d4aa' : '#a1a1aa',
        fontSize: '12px',
        fontWeight: active ? 700 : 500,
        cursor: 'pointer',
        transition: 'all 0.2s ease',
        display: 'flex',
        alignItems: 'center',
        gap: '6px',
        whiteSpace: 'nowrap',
        fontFamily: 'inherit',
      }}
    >
      <span>{tab.icon}</span>
      <span>{tab.label}</span>
      <span style={{
        fontSize: '9px',
        background: active ? '#00d4aa30' : '#ffffff10',
        padding: '1px 5px',
        borderRadius: '4px',
        color: active ? '#00d4aa' : '#71717a',
        fontWeight: 700,
      }}>
        {tab.features.length}
      </span>
    </button>
  );
}

function StylePreview({ styles, type }: { styles: typeof TOGGLE_STYLES; type: 'toggle' | 'slider' }) {
  const [selected, setSelected] = useState(0);
  return (
    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(min(100%, 180px), 1fr))', gap: '8px' }}>
      {styles.map((s, i) => (
        <button
          key={s.name}
          onClick={() => setSelected(i)}
          style={{
            padding: '12px',
            background: selected === i ? '#00d4aa15' : '#0d0d15',
            border: `1px solid ${selected === i ? '#00d4aa50' : '#1e1e30'}`,
            borderRadius: '8px',
            cursor: 'pointer',
            textAlign: 'left',
            transition: 'all 0.2s ease',
            fontFamily: 'inherit',
          }}
        >
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            <span style={{ fontSize: '16px' }}>{s.icon}</span>
            <span style={{ fontSize: '12px', fontWeight: 700, color: selected === i ? '#00d4aa' : '#e4e4e7' }}>{s.name}</span>
          </div>
          <p style={{ fontSize: '10px', color: '#71717a', marginTop: '4px' }}>{s.desc}</p>
          {type === 'toggle' && (
            <div style={{
              marginTop: '8px',
              width: '36px',
              height: '18px',
              borderRadius: s.name === 'Fill' ? '4px' : '9px',
              background: selected === i ? '#00d4aa' : '#333',
              position: 'relative',
              transition: 'all 0.3s ease',
            }}>
              {s.name === 'Dot' && (
                <div style={{
                  width: '14px', height: '14px', borderRadius: '50%', background: '#fff',
                  position: 'absolute', top: '2px', left: selected === i ? '20px' : '2px',
                  transition: 'all 0.3s ease',
                }} />
              )}
              {s.name === 'Check' && (
                <div style={{
                  position: 'absolute', top: '50%', left: '50%', transform: 'translate(-50%, -50%)',
                  fontSize: '12px', color: '#fff',
                }}>{selected === i ? '✓' : '✗'}</div>
              )}
              {s.name === 'Slash' && (
                <div style={{
                  position: 'absolute', top: '50%', left: '50%',
                  transform: `translate(-50%, -50%) rotate(${selected === i ? '0' : '45'}deg)`,
                  width: '16px', height: '2px', background: '#fff', transition: 'all 0.3s ease',
                }} />
              )}
            </div>
          )}
          {type === 'slider' && (
            <div style={{
              marginTop: '8px',
              width: '100%',
              height: s.name === 'Thin' ? '4px' : s.name === 'Thick' ? '16px' : '10px',
              borderRadius: '5px',
              background: '#333',
              position: 'relative',
              overflow: 'hidden',
              boxShadow: s.name === 'Glow' ? '0 0 10px #00d4aa40' : 'none',
            }}>
              <div style={{
                width: '60%', height: '100%', borderRadius: '5px',
                background: selected === i ? '#00d4aa' : '#555',
                transition: 'all 0.3s ease',
                boxShadow: s.name === 'Glow' ? '0 0 12px #00d4aa60' : 'none',
              }} />
            </div>
          )}
        </button>
      ))}
    </div>
  );
}

function GhostModeDemo() {
  const [ghostActive, setGhostActive] = useState(false);
  const [hovered, setHovered] = useState(false);

  return (
    <div className="fade-up delay-2" style={{ marginTop: '20px' }}>
      <h3 style={{ fontSize: '16px', fontWeight: 700, color: '#f59e0b', marginBottom: '12px', display: 'flex', alignItems: 'center', gap: '8px' }}>
        👻 Ghost Mode — Demo Interativo
      </h3>
      <div style={{ display: 'flex', gap: '12px', alignItems: 'center', marginBottom: '12px' }}>
        <button
          onClick={() => setGhostActive(!ghostActive)}
          style={{
            padding: '8px 16px',
            background: ghostActive ? '#f59e0b' : '#333',
            color: ghostActive ? '#000' : '#fff',
            border: 'none',
            borderRadius: '6px',
            fontSize: '12px',
            fontWeight: 700,
            cursor: 'pointer',
            transition: 'all 0.3s ease',
            fontFamily: 'inherit',
          }}
        >
          {ghostActive ? '👻 Ghost ON' : '💤 Ghost OFF'}
        </button>
        <span style={{ fontSize: '11px', color: '#71717a' }}>
          {ghostActive ? 'Passa o rato por cima do painel abaixo ↓' : 'Clica para ativar o demo'}
        </span>
      </div>
      <div
        onMouseEnter={() => setHovered(true)}
        onMouseLeave={() => setHovered(false)}
        style={{
          padding: '20px',
          background: '#12121c',
          border: '1px solid #1e1e30',
          borderRadius: '10px',
          opacity: ghostActive ? (hovered ? 1 : 0.05) : 1,
          transition: 'opacity 0.4s ease',
          position: 'relative',
        }}
      >
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <span style={{ fontSize: '14px', fontWeight: 700 }}>🐍 MEDUSA Panel</span>
          <span style={{ fontSize: '10px', color: '#00d4aa' }}>v13 ARCHITECT</span>
        </div>
        <div style={{ marginTop: '10px', display: 'flex', gap: '6px' }}>
          {['ESP ON', 'Aimbot ON', 'Fly OFF'].map(s => (
            <span key={s} style={{
              fontSize: '9px', padding: '3px 8px', borderRadius: '4px',
              background: s.includes('ON') ? '#22c55e20' : '#ef444420',
              color: s.includes('ON') ? '#22c55e' : '#ef4444',
              fontWeight: 700,
            }}>{s}</span>
          ))}
        </div>
        {ghostActive && !hovered && (
          <div style={{
            position: 'absolute', inset: 0, display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontSize: '11px', color: '#f59e0b', fontWeight: 700, pointerEvents: 'none',
          }}>
            👻 Invisível — Hover para ver
          </div>
        )}
      </div>
    </div>
  );
}

function RGBDemo() {
  const [rgbSpeed, setRGBSpeed] = useState(5);
  const canvasRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    let frame: number;
    let hue = 0;
    const animate = () => {
      hue = (hue + rgbSpeed * 0.5) % 360;
      if (canvasRef.current) {
        const el = canvasRef.current;
        el.style.borderColor = `hsl(${hue}, 80%, 55%)`;
        const title = el.querySelector('.rgb-title') as HTMLElement;
        if (title) title.style.color = `hsl(${hue}, 80%, 55%)`;
        const indicator = el.querySelector('.rgb-indicator') as HTMLElement;
        if (indicator) indicator.style.background = `hsl(${hue}, 80%, 55%)`;
      }
      frame = requestAnimationFrame(animate);
    };
    frame = requestAnimationFrame(animate);
    return () => cancelAnimationFrame(frame);
  }, [rgbSpeed]);

  return (
    <div className="fade-up delay-3" style={{ marginTop: '20px' }}>
      <h3 style={{ fontSize: '16px', fontWeight: 700, color: '#ec4899', marginBottom: '12px', display: 'flex', alignItems: 'center', gap: '8px' }}>
        🌈 RGB Engine — Demo Interativo
      </h3>
      <div style={{ marginBottom: '12px', display: 'flex', alignItems: 'center', gap: '12px' }}>
        <span style={{ fontSize: '11px', color: '#71717a', minWidth: '80px' }}>Velocidade: {rgbSpeed}</span>
        <input
          type="range" min="1" max="10" value={rgbSpeed}
          onChange={e => setRGBSpeed(Number(e.target.value))}
          style={{ flex: 1, accentColor: '#00d4aa', height: '4px' }}
        />
      </div>
      <div ref={canvasRef} style={{
        padding: '16px',
        background: '#0d0d15',
        border: '2px solid #00d4aa',
        borderRadius: '10px',
        transition: 'border-color 0.1s',
      }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <span className="rgb-title" style={{ fontSize: '16px', fontWeight: 800, transition: 'color 0.1s' }}>🐍 MEDUSA</span>
          <span style={{ fontSize: '10px', color: '#71717a' }}>v13 ARCHITECT</span>
        </div>
        <div style={{ marginTop: '10px', display: 'flex', gap: '6px', position: 'relative' }}>
          {['📊', '🎯', '👁️', '🏃', '⚔️'].map((icon, i) => (
            <div key={i} style={{
              width: '32px', height: '32px', background: '#12121c', borderRadius: '6px',
              display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '14px',
              border: i === 0 ? 'none' : '1px solid #1e1e30',
              position: 'relative',
            }}>
              {icon}
              {i === 0 && <div className="rgb-indicator" style={{
                position: 'absolute', left: 0, bottom: '-2px', width: '100%', height: '2px',
                borderRadius: '1px', transition: 'background 0.1s',
              }} />}
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

function ThemeGrid() {
  const [selected, setSelected] = useState(0);
  return (
    <div className="fade-up delay-4" style={{ marginTop: '20px' }}>
      <h3 style={{ fontSize: '16px', fontWeight: 700, color: '#a855f7', marginBottom: '12px' }}>
        🎨 Preset Themes
      </h3>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(min(100%, 160px), 1fr))', gap: '8px' }}>
        {THEME_PRESETS.map((t, i) => (
          <button
            key={t.name}
            onClick={() => setSelected(i)}
            style={{
              padding: '12px',
              background: selected === i ? `${t.accent}10` : '#0d0d15',
              border: `1px solid ${selected === i ? `${t.accent}50` : '#1e1e30'}`,
              borderRadius: '8px',
              cursor: 'pointer',
              textAlign: 'left',
              transition: 'all 0.2s ease',
              fontFamily: 'inherit',
            }}
          >
            <div style={{ fontSize: '13px', fontWeight: 700, color: selected === i ? t.accent : '#e4e4e7', marginBottom: '8px' }}>
              {t.name}
            </div>
            <div style={{ display: 'flex', gap: '4px' }}>
              {t.colors.map((c, j) => (
                <div key={j} style={{
                  width: '20px', height: '20px', borderRadius: '4px', background: c,
                  border: '1px solid #ffffff15',
                }} />
              ))}
            </div>
          </button>
        ))}
      </div>
    </div>
  );
}

// ─── MAIN APP ──────────────────────────────────────────

export default function App() {
  const [activeTab, setActiveTab] = useState('status');
  const [showLoadstring, setShowLoadstring] = useState(false);
  const loadstringRef = useRef<HTMLDivElement>(null);
  const activeTabData = TABS.find(t => t.id === activeTab)!;

  const totalFeatures = TABS.reduce((sum, t) => sum + t.features.length, 0);

  useEffect(() => {
    if (showLoadstring && loadstringRef.current) {
      loadstringRef.current.scrollIntoView({ behavior: 'smooth', block: 'center' });
    }
  }, [showLoadstring]);

  return (
    <div style={{ minHeight: '100vh', background: '#08080e', position: 'relative', overflow: 'hidden' }}>
      {/* ═══ BACKGROUND EFFECTS ═══ */}
      <div style={{
        position: 'fixed', top: '-20%', left: '-10%', width: '500px', height: '500px',
        background: 'radial-gradient(circle, #00d4aa08 0%, transparent 70%)',
        borderRadius: '50%', pointerEvents: 'none', zIndex: 0,
      }} />
      <div style={{
        position: 'fixed', bottom: '-20%', right: '-10%', width: '600px', height: '600px',
        background: 'radial-gradient(circle, #a855f708 0%, transparent 70%)',
        borderRadius: '50%', pointerEvents: 'none', zIndex: 0,
      }} />

      {/* ═══ HEADER ═══ */}
      <header style={{
        position: 'sticky', top: 0, zIndex: 50,
        background: 'rgba(8, 8, 14, 0.9)',
        backdropFilter: 'blur(16px)',
        borderBottom: '1px solid #1e1e3040',
        padding: '12px 0',
      }}>
        <div style={{ maxWidth: '1100px', margin: '0 auto', padding: '0 20px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
            <span style={{ fontSize: '24px' }}>🐍</span>
            <span style={{ fontSize: '18px', fontWeight: 800, letterSpacing: '1px' }}>MEDUSA</span>
            <span style={{
              fontSize: '9px', fontWeight: 800, padding: '2px 8px',
              borderRadius: '4px', background: '#00d4aa20', color: '#00d4aa',
              border: '1px solid #00d4aa30',
            }}>v13 ARCHITECT</span>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
            <span style={{ fontSize: '10px', color: '#71717a' }}>by .donatorexe.</span>
            <span style={{
              fontSize: '9px', padding: '3px 8px', borderRadius: '4px',
              background: '#3b82f620', color: '#3b82f6', fontWeight: 700,
              border: '1px solid #3b82f630',
            }}>XENO OPTIMIZED</span>
          </div>
        </div>
      </header>

      <main style={{ maxWidth: '1100px', margin: '0 auto', padding: '0 20px', position: 'relative', zIndex: 1 }}>
        {/* ═══ HERO ═══ */}
        <section style={{ padding: '60px 0 40px', textAlign: 'center' }}>
          <div className="fade-up" style={{ marginBottom: '16px' }}>
            <span style={{ fontSize: '56px' }} className="float-anim" role="img">🐍</span>
          </div>
          <h1 className="fade-up delay-1" style={{ fontSize: 'clamp(28px, 5vw, 42px)', fontWeight: 900, letterSpacing: '3px', marginBottom: '8px' }}>
            <span className="gradient-text">MEDUSA</span>{' '}
            <span style={{ color: '#71717a', fontWeight: 400, fontSize: 'clamp(14px, 2.5vw, 20px)' }}>v13 ARCHITECT</span>
          </h1>
          <p className="fade-up delay-2" style={{ color: '#71717a', fontSize: '14px', maxWidth: '500px', margin: '0 auto 24px' }}>
            Super Script Ultra-Customizável para Roblox — Otimizado para Xeno Executor
          </p>

          {/* Stats */}
          <div className="fade-up delay-3" style={{
            display: 'grid',
            gridTemplateColumns: 'repeat(auto-fit, minmax(90px, 1fr))',
            gap: '8px',
            maxWidth: '600px',
            margin: '0 auto 32px',
          }}>
            {STATS.map((s) => (
              <div key={s.label} style={{
                padding: '12px 8px',
                background: '#12121c',
                borderRadius: '8px',
                border: '1px solid #1e1e30',
                textAlign: 'center',
              }}>
                <div style={{ fontSize: '14px', marginBottom: '4px' }}>{s.icon}</div>
                <div style={{ fontSize: '18px', fontWeight: 800, color: '#00d4aa' }}>{s.value}</div>
                <div style={{ fontSize: '9px', color: '#71717a', fontWeight: 600 }}>{s.label}</div>
              </div>
            ))}
          </div>

          {/* Action Buttons */}
          <div className="fade-up delay-4" style={{ display: 'flex', gap: '12px', justifyContent: 'center', flexWrap: 'wrap' }}>
            <button
              onClick={() => setShowLoadstring(!showLoadstring)}
              className="pulse-glow"
              style={{
                padding: '14px 32px',
                background: 'linear-gradient(135deg, #00d4aa, #00a885)',
                color: '#000',
                border: 'none',
                borderRadius: '10px',
                fontWeight: 800,
                fontSize: '14px',
                cursor: 'pointer',
                letterSpacing: '0.5px',
                fontFamily: 'inherit',
              }}
            >
              🐍 {showLoadstring ? 'Esconder Loadstring' : 'Obter Script'}
            </button>
            <CopyButton
              text={`loadstring(game:HttpGet("https://raw.githubusercontent.com/YOUR_USER/YOUR_REPO/main/Medusa.lua"))()`}
              label="Copiar Loadstring"
            />
            <button
              onClick={() => {
                const blob = new Blob([scriptRaw], { type: 'text/plain' });
                const url = URL.createObjectURL(blob);
                const a = document.createElement('a');
                a.href = url;
                a.download = 'Medusa.lua';
                a.click();
                URL.revokeObjectURL(url);
              }}
              style={{
                padding: '14px 28px',
                background: 'linear-gradient(135deg, #3b82f6, #6366f1)',
                border: 'none',
                borderRadius: '12px',
                color: 'white',
                fontWeight: 700,
                fontSize: '15px',
                cursor: 'pointer',
                transition: 'all 0.3s',
              }}
              onMouseEnter={e => { e.currentTarget.style.transform = 'scale(1.05)'; e.currentTarget.style.boxShadow = '0 0 25px rgba(59,130,246,0.5)'; }}
              onMouseLeave={e => { e.currentTarget.style.transform = 'scale(1)'; e.currentTarget.style.boxShadow = 'none'; }}
            >
              📥 Download Medusa.lua
            </button>
          </div>
        </section>

        {/* ═══ LOADSTRING SECTION ═══ */}
        {showLoadstring && (
          <section ref={loadstringRef} className="scale-in" style={{
            maxWidth: '700px', margin: '0 auto 40px',
            padding: '24px',
            background: '#0d0d15',
            border: '1px solid #00d4aa30',
            borderRadius: '12px',
            boxShadow: '0 0 40px #00d4aa10',
          }}>
            <h3 style={{ fontSize: '16px', fontWeight: 700, marginBottom: '16px', display: 'flex', alignItems: 'center', gap: '8px' }}>
              📦 Como usar o Medusa v13
            </h3>

            <div style={{ marginBottom: '16px' }}>
              <p style={{ fontSize: '12px', color: '#a1a1aa', marginBottom: '12px' }}>
                <strong>Passo 1:</strong> Faz upload do ficheiro <code className="code-font" style={{ background: '#1e1e30', padding: '2px 6px', borderRadius: '4px', color: '#00d4aa' }}>Medusa_v13.txt</code> para o teu GitHub
              </p>
              <p style={{ fontSize: '12px', color: '#a1a1aa', marginBottom: '12px' }}>
                <strong>Passo 2:</strong> Copia o URL Raw do ficheiro
              </p>
              <p style={{ fontSize: '12px', color: '#a1a1aa', marginBottom: '12px' }}>
                <strong>Passo 3:</strong> Cola no teu executor Xeno e executa:
              </p>
            </div>

            <div style={{
              background: '#08080e', padding: '16px', borderRadius: '8px',
              border: '1px solid #1e1e30', marginBottom: '16px',
              fontFamily: "'JetBrains Mono', Consolas, monospace",
              fontSize: '12px', lineHeight: 1.8,
              overflowX: 'auto',
            }}>
              <span style={{ color: '#71717a' }}>-- Medusa v13 ARCHITECT — Xeno Executor</span><br />
              <span style={{ color: '#a855f7' }}>loadstring</span>
              <span style={{ color: '#e4e4e7' }}>(</span>
              <span style={{ color: '#3b82f6' }}>game</span>
              <span style={{ color: '#e4e4e7' }}>:</span>
              <span style={{ color: '#22c55e' }}>HttpGet</span>
              <span style={{ color: '#e4e4e7' }}>(</span>
              <span style={{ color: '#f59e0b' }}>"URL_DO_TEU_RAW"</span>
              <span style={{ color: '#e4e4e7' }}>))()</span>
            </div>

            <div style={{ display: 'flex', gap: '8px', flexWrap: 'wrap' }}>
              <span style={{ fontSize: '10px', color: '#71717a', padding: '4px 8px', background: '#1e1e30', borderRadius: '4px' }}>✅ Xeno</span>
              <span style={{ fontSize: '10px', color: '#71717a', padding: '4px 8px', background: '#1e1e30', borderRadius: '4px' }}>✅ Fluxus</span>
              <span style={{ fontSize: '10px', color: '#71717a', padding: '4px 8px', background: '#1e1e30', borderRadius: '4px' }}>✅ Delta</span>
              <span style={{ fontSize: '10px', color: '#71717a', padding: '4px 8px', background: '#1e1e30', borderRadius: '4px' }}>✅ Wave</span>
              <span style={{ fontSize: '10px', color: '#71717a', padding: '4px 8px', background: '#1e1e30', borderRadius: '4px' }}>✅ Solara</span>
            </div>
          </section>
        )}

        {/* ═══ FEATURES BROWSER ═══ */}
        <section style={{ paddingBottom: '60px' }}>
          <div className="fade-up delay-5" style={{ textAlign: 'center', marginBottom: '24px' }}>
            <h2 style={{ fontSize: '24px', fontWeight: 800, marginBottom: '6px' }}>
              ⚡ {totalFeatures} Features — {TABS.length} Tabs
            </h2>
            <p style={{ fontSize: '12px', color: '#71717a' }}>Explora todas as funcionalidades do Medusa v13 ARCHITECT</p>
          </div>

          {/* Tab Bar */}
          <div className="fade-up delay-6" style={{
            display: 'flex',
            gap: '4px',
            overflowX: 'auto',
            paddingBottom: '8px',
            marginBottom: '20px',
            WebkitOverflowScrolling: 'touch',
          }}>
            {TABS.map(tab => (
              <TabButton key={tab.id} tab={tab} active={activeTab === tab.id} onClick={() => setActiveTab(tab.id)} />
            ))}
          </div>

          {/* Tab Content */}
          <div key={activeTab} className="fade-in" style={{ minHeight: '400px' }}>
            {/* Tab Header */}
            <div style={{
              padding: '16px 20px',
              background: '#0d0d15',
              borderRadius: '10px 10px 0 0',
              border: '1px solid #1e1e30',
              borderBottom: 'none',
              display: 'flex',
              justifyContent: 'space-between',
              alignItems: 'center',
            }}>
              <div>
                <h3 style={{ fontSize: '18px', fontWeight: 800, display: 'flex', alignItems: 'center', gap: '8px' }}>
                  <span>{activeTabData.icon}</span>
                  <span>{activeTabData.label}</span>
                </h3>
                <p style={{ fontSize: '11px', color: '#71717a', marginTop: '2px' }}>
                  {activeTabData.features.length} {activeTabData.features.length === 1 ? 'feature' : 'features'} nesta secção
                </p>
              </div>
              <span style={{
                fontSize: '11px', fontWeight: 700, padding: '4px 10px',
                borderRadius: '6px', background: '#00d4aa15', color: '#00d4aa',
                border: '1px solid #00d4aa25',
              }}>
                Tab {TABS.findIndex(t => t.id === activeTab) + 1}/{TABS.length}
              </span>
            </div>

            {/* Features Grid */}
            <div style={{
              padding: '16px',
              background: '#0a0a12',
              borderRadius: '0 0 10px 10px',
              border: '1px solid #1e1e30',
              borderTop: '1px solid #1e1e3030',
            }}>
              <div style={{
                display: 'grid',
                gridTemplateColumns: 'repeat(auto-fill, minmax(min(100%, 340px), 1fr))',
                gap: '8px',
              }}>
                {activeTabData.features.map((f, i) => (
                  <FeatureCard key={f.name} f={f} index={i} />
                ))}
              </div>

              {/* Special sections per tab */}
              {activeTab === 'gui' && (
                <div style={{ marginTop: '24px' }}>
                  <h3 style={{ fontSize: '16px', fontWeight: 700, color: '#22c55e', marginBottom: '12px' }}>
                    🔘 Toggle Styles (4 variantes)
                  </h3>
                  <StylePreview styles={TOGGLE_STYLES} type="toggle" />

                  <h3 style={{ fontSize: '16px', fontWeight: 700, color: '#3b82f6', marginBottom: '12px', marginTop: '24px' }}>
                    🎚️ Slider Styles (4 variantes)
                  </h3>
                  <StylePreview styles={SLIDER_STYLES} type="slider" />
                </div>
              )}

              {activeTab === 'themes' && (
                <>
                  <RGBDemo />
                  <ThemeGrid />
                </>
              )}

              {activeTab === 'misc' && (
                <GhostModeDemo />
              )}
            </div>
          </div>

          {/* Compatibility Table */}
          <div className="fade-up" style={{ marginTop: '40px' }}>
            <h2 style={{ fontSize: '20px', fontWeight: 800, marginBottom: '16px', textAlign: 'center' }}>
              🔧 Compatibilidade por Executor
            </h2>
            <div style={{ overflowX: 'auto' }}>
              <table style={{
                width: '100%', borderCollapse: 'collapse',
                background: '#0d0d15', borderRadius: '10px',
                overflow: 'hidden', fontSize: '12px',
              }}>
                <thead>
                  <tr style={{ background: '#12121c' }}>
                    <th style={{ padding: '12px', textAlign: 'left', color: '#71717a', fontWeight: 700, borderBottom: '1px solid #1e1e30' }}>Feature</th>
                    {['Xeno', 'Fluxus', 'Delta', 'Wave', 'Solara'].map(e => (
                      <th key={e} style={{ padding: '12px', textAlign: 'center', color: e === 'Xeno' ? '#00d4aa' : '#a1a1aa', fontWeight: 700, borderBottom: '1px solid #1e1e30' }}>
                        {e === 'Xeno' ? '🐍 ' : ''}{e}
                      </th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {[
                    { name: 'Aimbot + Silent Aim', xeno: '✅', fluxus: '✅', delta: '✅', wave: '✅', solara: '✅' },
                    { name: 'ESP (Highlights)', xeno: '✅', fluxus: '✅', delta: '✅', wave: '✅', solara: '✅' },
                    { name: 'ESP 3D Boxes', xeno: '✅', fluxus: '✅', delta: '✅', wave: '✅', solara: '✅' },
                    { name: 'Tracers + Skeleton', xeno: '✅', fluxus: '✅', delta: '✅', wave: '✅', solara: '✅' },
                    { name: 'Ghost Mode', xeno: '✅', fluxus: '✅', delta: '✅', wave: '✅', solara: '✅' },
                    { name: 'StreamProof (gethui)', xeno: '✅', fluxus: '⚠️', delta: '⚠️', wave: '✅', solara: '✅' },
                    { name: 'Prediction', xeno: '✅', fluxus: '✅', delta: '✅', wave: '✅', solara: '✅' },
                    { name: 'Config Save/Load', xeno: '✅', fluxus: '✅', delta: '⚠️', wave: '✅', solara: '✅' },
                    { name: 'Silent Aim (hookmetamethod)', xeno: '✅', fluxus: '✅', delta: '✅', wave: '✅', solara: '⚠️' },
                    { name: 'Speed Bypass', xeno: '✅', fluxus: '✅', delta: '✅', wave: '✅', solara: '✅' },
                  ].map((row, i) => (
                    <tr key={row.name} style={{ background: i % 2 === 0 ? '#0d0d15' : '#0a0a12' }}>
                      <td style={{ padding: '10px 12px', color: '#e4e4e7', fontWeight: 600, borderBottom: '1px solid #1e1e3030' }}>{row.name}</td>
                      {[row.xeno, row.fluxus, row.delta, row.wave, row.solara].map((v, j) => (
                        <td key={j} style={{ padding: '10px', textAlign: 'center', borderBottom: '1px solid #1e1e3030', fontSize: '14px' }}>{v}</td>
                      ))}
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </section>
      </main>

      {/* ═══ FOOTER ═══ */}
      <footer style={{
        borderTop: '1px solid #1e1e30',
        padding: '24px 0',
        textAlign: 'center',
        background: '#0a0a10',
      }}>
        <div style={{ maxWidth: '1100px', margin: '0 auto', padding: '0 20px' }}>
          <p style={{ fontSize: '12px', color: '#71717a', marginBottom: '4px' }}>
            🐍 MEDUSA v13 ARCHITECT — Made by <span style={{ color: '#00d4aa', fontWeight: 700 }}>.donatorexe.</span>
          </p>
          <p style={{ fontSize: '10px', color: '#52525b' }}>
            Xeno Optimized • {totalFeatures} Features • {TABS.length} Tabs • {THEME_PRESETS.length} Themes • Ghost Mode • RGB Engine
          </p>
        </div>
      </footer>
    </div>
  );
}
