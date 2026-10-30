// Native Figma source: editable text, vectors, Auto Layout, variants and links.
// Import manifest.json as a development plugin. No network or external assets.
const palette = {navy:'#14213D', emerald:'#10B981', gray:'#F5F7FA', white:'#FFFFFF', muted:'#64748B', red:'#EF4444'};
const paths = {
  back:'<path d="m12 5-7 7 7 7M5 12h15"/>',
  sun:'<circle cx="12" cy="12" r="4"/><path d="M12 1v2M12 21v2M1 12h2M21 12h2M4 4l2 2M18 18l2 2M4 20l2-2M18 6l2-2"/>',
  moon:'<path d="M21 13A9 9 0 0 1 11 3a9 9 0 1 0 10 10Z"/>',
  system:'<rect x="3" y="3" width="18" height="14" rx="2"/><path d="M8 21h8M12 17v4"/>',
  check:'<path d="m5 12 4 4L19 6"/>',
  chevron:'<path d="m9 5 7 7-7 7"/>',
  tune:'<path d="M3 6h18M3 12h18M3 18h18"/><circle cx="8" cy="6" r="2"/><circle cx="16" cy="12" r="2"/><circle cx="9" cy="18" r="2"/>',
  palette:'<path d="M12 3a9 9 0 1 0 0 18h2a2 2 0 0 0 0-4h-1a2 2 0 0 1 0-4h4a4 4 0 0 0 4-4c0-4-5-6-9-6Z"/><circle cx="7" cy="9" r="1"/><circle cx="11" cy="6" r="1"/><circle cx="16" cy="7" r="1"/>',
  bell:'<path d="M18 8a6 6 0 0 0-12 0c0 7-3 7-3 9h18c0-2-3-2-3-9M10 21h4"/>',
  wallet:'<rect x="3" y="5" width="18" height="16" rx="3"/><path d="M3 8V5a2 2 0 0 1 2-2h12M16 11h5v6h-5z"/>',
  calendar:'<rect x="3" y="5" width="18" height="16" rx="2"/><path d="M7 2v6M17 2v6M3 10h18M7 14h3M14 14h3"/>',
  money:'<rect x="2" y="5" width="20" height="14" rx="2"/><circle cx="12" cy="12" r="3"/><path d="M5 9h1M18 15h1"/>',
  language:'<circle cx="12" cy="12" r="9"/><ellipse cx="12" cy="12" rx="4" ry="9"/><path d="M3 12h18"/>',
  receipt:'<path d="M5 2h14v20l-3-2-4 2-4-2-3 2zM8 7h8M8 11h8M8 15h5"/>',
  chart:'<path d="M4 20V9M10 20V4M16 20v-8M22 20H2"/>',
  lock:'<rect x="4" y="10" width="16" height="12" rx="2"/><path d="M8 10V6a4 4 0 0 1 8 0v4M12 15v3"/>',
  fingerprint:'<path d="M3 12a9 9 0 0 1 18 0M6 17v-5a6 6 0 0 1 12 0v7M9 21v-9a3 3 0 0 1 6 0v9M12 12v10"/>',
  shield:'<path d="m12 2 9 4v6c0 5-9 10-9 10S3 17 3 12V6z"/><path d="m8 12 3 3 5-6"/>',
  download:'<path d="M12 2v13m-5-5 5 5 5-5M3 16v5h18v-5"/>',
  cloud:'<path d="M6 18a5 5 0 1 1 1-10 6 6 0 0 1 12 2 4 4 0 0 1-1 8M12 12v10m-4-4 4 4 4-4"/>',
  trash:'<path d="M3 6h18M9 6V3h6v3M6 6l1 15h10l1-15M10 10v7M14 10v7"/>',
  info:'<circle cx="12" cy="12" r="9"/><path d="M12 10v7M12 6v1"/>',
  file:'<path d="M5 2h9l5 5v15H5zM14 2v6h5M8 12h8M8 16h8"/>',
  feedback:'<path d="M3 3h18v14H8l-5 4zM7 7h10M7 11h7"/>',
  logout:'<path d="M10 3H3v18h7M10 12h12m-5-5 5 5-5 5"/>',
  warning:'<path d="m12 2 11 20H1zM12 8v6M12 17v1"/>',
  home:'<path d="m3 10 9-8 9 8v12h-7v-8h-4v8H3z"/>',
  grid:'<rect x="3" y="3" width="7" height="7" rx="1"/><rect x="14" y="3" width="7" height="7" rx="1"/><rect x="3" y="14" width="7" height="7" rx="1"/><rect x="14" y="14" width="7" height="7" rx="1"/>',
  person:'<circle cx="12" cy="7" r="4"/><path d="M4 21v-2a8 8 0 0 1 16 0v2"/>',
  settings:'<path d="m9 2-1 3-3 1-2 3 2 3-2 3 2 3 3 1 1 3h6l1-3 3-1 2-3-2-3 2-3-2-3-3-1-1-3Z"/><circle cx="12" cy="12" r="3"/>',
};
function rgb(hex){const n=parseInt(hex.slice(1),16);return {r:(n>>16)/255,g:((n>>8)&255)/255,b:(n&255)/255};}
function fill(hex){return [{type:'SOLID',color:rgb(hex)}];}
function frame(name,dir='VERTICAL',pad=0,gap=0,color=null){const n=figma.createFrame();n.name=name;n.layoutMode=dir;n.primaryAxisSizingMode='AUTO';n.counterAxisSizingMode='AUTO';n.paddingTop=n.paddingBottom=n.paddingLeft=n.paddingRight=pad;n.itemSpacing=gap;n.fills=color?fill(color):[];n.clipsContent=false;return n;}
function fixed(n,w,h){n.resize(w,h);n.primaryAxisSizingMode=n.counterAxisSizingMode='FIXED';return n;}
function text(value,size=12,weight='Regular',color=palette.navy,width=null){const n=figma.createText();n.fontName={family:'Inter',style:weight};n.fontSize=size;n.characters=value;n.fills=fill(color);n.name=value;n.textAutoResize='WIDTH_AND_HEIGHT';if(width){n.resize(width,n.height);n.textAutoResize='HEIGHT';}return n;}
function icon(name,color=palette.navy,size=20){const n=figma.createNodeFromSvg(`<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="${color}" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round">${paths[name]||paths.info}</svg>`);n.resize(size,size);n.name=`Icon / ${name}`;return n;}
function add(n,...children){children.forEach(c=>n.appendChild(c));return n;}
function rounded(n,r=16){n.cornerRadius=r;return n;}
const links=[];
function link(n,destination){links.push(()=>n.setReactionsAsync([{trigger:{type:'ON_CLICK'},actions:[{type:'NODE',destinationId:destination.id,navigation:'NAVIGATE',transition:null,preserveScrollPosition:true}]}]));}
let library, switches;
function reusable(n,name){const c=figma.createComponentFromNode(n);c.name=name;library.appendChild(c);return c.createInstance();}
function button(label,color,width=145,outline=false){const n=fixed(rounded(frame(label,'HORIZONTAL',12,8,outline?palette.white:color),12),width,48);n.primaryAxisAlignItems=n.counterAxisAlignItems='CENTER';if(outline){n.strokes=fill('#E2E8F0');n.strokeWeight=1;}add(n,text(label,12,'Semi Bold',outline?color:palette.white));return reusable(n,`Button / ${label}`);}
function section(name,glyph,fg,muted){const n=frame(`Section / ${name}`,'VERTICAL',0,12);const h=frame(`Heading / ${name}`,'HORIZONTAL',0,8);h.counterAxisAlignItems='CENTER';add(h,icon(glyph,muted,17),text(name,15,'Semi Bold',fg));n.appendChild(h);return n;}
function card(name,bg,border){const n=rounded(frame(name,'VERTICAL',0,0,bg));n.resize(353,100);n.counterAxisSizingMode='FIXED';n.strokes=fill(border);n.strokeWeight=1;n.clipsContent=true;return n;}

async function main(){
  await Promise.all(['Regular','Medium','Semi Bold','Bold'].map(style=>figma.loadFontAsync({family:'Inter',style})));
  library=frame('Spendly / Settings component library','VERTICAL',24,20,palette.gray);library.x=1450;figma.currentPage.appendChild(library);
  const switchComponents=[];
  for(const enabled of [false,true]){
    const n=figma.createComponent();n.name=`State=${enabled?'On':'Off'}`;n.resize(40,24);n.cornerRadius=12;n.fills=fill(enabled?palette.emerald:'#CBD5E1');
    const knob=figma.createEllipse();knob.name='Thumb';knob.resize(18,18);knob.x=enabled?19:3;knob.y=3;knob.fills=fill(palette.white);n.appendChild(knob);library.appendChild(n);switchComponents.push(n);
  }
  switches=figma.combineAsVariants(switchComponents,library);switches.name='Switch / State';
  for(let i=0;i<2;i++)links.push(()=>switchComponents[i].setReactionsAsync([{trigger:{type:'ON_CLICK'},actions:[{type:'NODE',destinationId:switchComponents[1-i].id,navigation:'CHANGE_TO',transition:null}]}]));
  const screens=[];const themeButtons=[];const actionRows=new Map();
  for(const [index,mode] of ['Light','Dark','System Default'].entries()){
    const dark=mode==='Dark', bg=dark?'#151B28':palette.white, low=dark?'#242C3D':palette.gray, fg=dark?'#F1F5F9':palette.navy, muted=dark?'#CBD5E1':palette.muted, border=dark?'#334155':'#E2E8F0';
    const screen=fixed(frame(`Spendly / Settings / ${mode} / 393 × 852`,'VERTICAL',0,0,bg),393,852);screen.clipsContent=true;screen.x=index*450;figma.currentPage.appendChild(screen);screens.push(screen);
    const header=fixed(frame('Header / Back + title + subtitle','VERTICAL',20,10,bg),393,112);
    const titleRow=frame('Title row','HORIZONTAL',0,12);titleRow.counterAxisAlignItems='CENTER';
    const back=fixed(rounded(frame('Back to Home','HORIZONTAL',0,0,low),22),44,44);back.primaryAxisAlignItems=back.counterAxisAlignItems='CENTER';add(back,icon('back',fg));
    add(titleRow,back,text('Settings',26,'Bold',fg));add(header,titleRow,text('Customize your Spendly experience.',13,'Regular',muted));screen.appendChild(header);
    const viewport=fixed(frame('Scrollable settings','VERTICAL',0,0,bg),393,668);viewport.clipsContent=true;viewport.overflowDirection='VERTICAL';screen.appendChild(viewport);
    const body=frame('Settings content / Auto Layout','VERTICAL',20,24,bg);body.resize(393,1900);body.counterAxisSizingMode='FIXED';viewport.appendChild(body);
    const appearance=section('Appearance','palette',fg,muted);const appearanceCard=card('Card / Appearance',bg,border);appearanceCard.paddingTop=appearanceCard.paddingBottom=appearanceCard.paddingLeft=appearanceCard.paddingRight=16;appearanceCard.itemSpacing=16;
    add(appearanceCard,text('Theme Mode',13,'Semi Bold',fg));const choices=frame('Theme selector / Clear selected states','HORIZONTAL',0,8);const buttons=[];
    for(const [label,glyph] of [['Light','sun'],['Dark','moon'],['System Default','system']]){
      const selected=label===mode;const choice=fixed(rounded(frame(`Theme / ${label} / ${selected?'Selected':'Default'}`,'VERTICAL',8,8,selected?(dark?'#123E35':'#ECFDF5'):low),12),101.7,82);choice.counterAxisAlignItems=choice.primaryAxisAlignItems='CENTER';
      if(selected){choice.strokes=fill(palette.emerald);choice.strokeWeight=1.5;}
      add(choice,icon(glyph,selected?palette.emerald:muted,22),text(label,10,selected?'Semi Bold':'Regular',fg));choices.appendChild(choice);buttons.push(choice);
    }themeButtons.push(buttons);appearanceCard.appendChild(choices);
    const accents=fixed(frame('Accent Color selection','HORIZONTAL',0,10),321,40);accents.counterAxisAlignItems='CENTER';const accentLabel=text('Accent Color',13,'Semi Bold',fg);accentLabel.layoutGrow=1;accents.appendChild(accentLabel);
    for(const c of [palette.emerald,'#6366F1','#0EA5E9','#F59E0B']){const swatch=fixed(rounded(frame(`Accent / ${c}${c===palette.emerald?' / Selected':''}`,'HORIZONTAL',0,0,c),15),28,28);swatch.primaryAxisAlignItems=swatch.counterAxisAlignItems='CENTER';if(c===palette.emerald)swatch.appendChild(icon('check',palette.white,17));accents.appendChild(swatch);}
    appearanceCard.appendChild(accents);
    const preview=fixed(rounded(frame('Selected theme / Preview','HORIZONTAL',12,12,low),12),321,68);preview.counterAxisAlignItems='CENTER';
    const balance=frame('Sample balance','VERTICAL',0,4);balance.layoutGrow=1;add(balance,text('THEME PREVIEW',9,'Semi Bold',muted),text('LKR 24,500.00',16,'Bold',fg));add(preview,icon('wallet',palette.emerald,22),balance,icon('check',palette.emerald,20));appearanceCard.appendChild(preview);appearance.appendChild(appearanceCard);body.appendChild(appearance);
    function row(title,glyph,value=null,toggle=null,destructive=false,subtitle=null){const n=fixed(frame(`Row / ${title}`,'HORIZONTAL',14,10,bg),353,62);n.counterAxisAlignItems='CENTER';const color=destructive?palette.red:fg;n.appendChild(icon(glyph,color,20));const label=frame('Text / Title + value','VERTICAL',0,4);label.layoutGrow=1;label.resize(205,34);label.counterAxisSizingMode='FIXED';add(label,text(title,12,'Medium',color,205));if(subtitle)label.appendChild(text(subtitle,10,'Regular',muted,205));n.appendChild(label);if(toggle!==null){n.appendChild(switchComponents[toggle?1:0].createInstance());}else{if(value)n.appendChild(text(value,10,'Regular',muted));if(title!=='App Version')n.appendChild(icon('chevron',muted,18));}const instance=reusable(n,`Settings row / ${mode} / ${title}`);if(!actionRows.has(title))actionRows.set(title,[]);actionRows.get(title).push({node:instance,origin:screen});return instance;}
    function group(title,glyph,rows){const s=section(title,glyph,fg,muted);const c=card(`Card / ${title}`,bg,border);rows.forEach(r=>c.appendChild(row(...r)));s.appendChild(c);body.appendChild(s);}
    group('Preferences','tune',[
      ['Currency','money',null,null,false,'LKR (Sri Lankan Rupee)'],['Language','language','English'],['First Day of Week','calendar','Monday'],['Date Format','calendar','DD/MM/YYYY']]);
    group('Notifications','bell',[
      ['Expense Reminders','receipt',null,true],['Daily Spending Summary','calendar',null,false],['Budget Limit Alerts','wallet',null,true],['Weekly Financial Reports','chart',null,false]]);
    group('Security','shield',[
      ['Change Password','lock'],['Enable Biometric Authentication','fingerprint'],['App Lock','lock','Off'],['Privacy Settings','shield']]);
    group('Data Management','cloud',[
      ['Export Expense Data','download'],['Backup & Restore','cloud'],['Clear App Data','trash',null,null,true]]);
    group('About','info',[
      ['About Spendly','info'],['App Version','system','1.0.0'],['Privacy Policy','shield'],['Terms & Conditions','file'],['Send Feedback','feedback']]);
    const logout=button('Logout',fg,353,true);body.appendChild(logout);if(!actionRows.has('Logout'))actionRows.set('Logout',[]);actionRows.get('Logout').push({node:logout,origin:screen});
    const del=fixed(frame('Delete Account / Destructive action','HORIZONTAL',12,0,bg),353,48);del.primaryAxisAlignItems=del.counterAxisAlignItems='CENTER';del.appendChild(text('Delete Account',12,'Semi Bold',palette.red));body.appendChild(del);if(!actionRows.has('Delete Account'))actionRows.set('Delete Account',[]);actionRows.get('Delete Account').push({node:del,origin:screen});
    body.appendChild(text('Spendly 1.0.0 · Local preview',10,'Regular',muted));
    const nav=fixed(frame('Bottom Navigation / Settings active','HORIZONTAL',8,0,bg),393,72);
    for(const [label,glyph] of [['Home','home'],['Settings','settings'],['Budgets','wallet'],['Categories','grid'],['Profile','person']]){
      const active=label==='Settings';const tab=fixed(rounded(frame(`Tab / ${label} / ${active?'Active':'Default'}`,'VERTICAL',6,5,active?(dark?'#123E35':'#ECFDF5'):bg),12),75.4,56);tab.primaryAxisAlignItems=tab.counterAxisAlignItems='CENTER';add(tab,icon(glyph,active?palette.emerald:muted,21),text(label,10,active?'Semi Bold':'Regular',fg));nav.appendChild(tab);
    }screen.appendChild(nav);
  }
  themeButtons.forEach(buttons=>buttons.forEach((button,i)=>link(button,screens[i])));
  let panelIndex=0;
  function panel(title,subtitle){const n=fixed(frame(`Flow / ${title}`,'VERTICAL',24,20,palette.white),393,852);n.x=(panelIndex%3)*450;n.y=960+Math.floor(panelIndex/3)*940;panelIndex++;figma.currentPage.appendChild(n);const back=frame('Back to Settings','HORIZONTAL',0,10);add(back,icon('back'),text('Settings',13,'Medium'));link(back,screens[0]);add(n,back,text(title,24,'Bold',palette.navy,345));if(subtitle)n.appendChild(text(subtitle,13,'Regular',palette.muted,345));return n;}
  for(const [title,options] of Object.entries({Currency:['LKR (Sri Lankan Rupee)','USD (US Dollar)','EUR (Euro)','GBP (British Pound)'],Language:['English','Sinhala','Tamil'],'First Day of Week':['Monday','Sunday','Saturday'],'Date Format':['DD/MM/YYYY','MM/DD/YYYY','YYYY-MM-DD']})){
    const p=panel(`Select ${title}`,'Choose your preferred display option.');
    options.forEach((option,i)=>{const r=fixed(rounded(frame(`Option / ${option} / ${i===0?'Selected':'Default'}`,'HORIZONTAL',16,12,i===0?'#ECFDF5':palette.gray),12),345,56);const t=text(option,12,'Medium');t.layoutGrow=1;add(r,t,icon(i===0?'check':'chevron',i===0?palette.emerald:palette.muted,18));p.appendChild(r);link(r,screens[0]);});
    (actionRows.get(title)||[]).forEach(({node})=>link(node,p));
  }
  const messages={
    'Change Password':'Update your password with a signed-in account. Authentication is not connected in the local preview.',
    'Enable Biometric Authentication':'Use your fingerprint or face recognition to unlock Spendly. Device authentication is not active in this preview.',
    'App Lock':'App lock is off. PIN and biometric enrollment require device integration.',
    'Privacy Settings':'Manage how your financial information is used. This preview keeps changes in the current app session.',
    'Export Expense Data':'Export your transactions in CSV format for your spreadsheet.',
    'Backup & Restore':'Create a temporary snapshot of your expenses, or restore a saved session snapshot. This preview does not store cloud backups.',
    'About Spendly':'A little clarity. A lot more control.\n\nTrack expenses, plan budgets, and understand monthly spending.',
    'Privacy Policy':'Draft policy placeholder for design review. A published policy will be provided before launch.',
    'Terms & Conditions':'Draft terms placeholder for design review. Published terms will be provided before launch.',
    'Send Feedback':'Tell us what would make Spendly better. Feedback delivery is not connected in this preview.',
  };
  for(const [title,message] of Object.entries(messages)){const p=panel(title,message);if(title==='Export Expense Data')p.appendChild(button('Copy CSV',palette.navy,345));if(title==='Backup & Restore')add(p,button('Create session backup',palette.navy,345),button('Restore session backup',palette.navy,345,true));(actionRows.get(title)||[]).forEach(({node})=>link(node,p));}
  for(const [title,message,confirm] of [
    ['Clear App Data','This removes all expense transactions from your current app session. Export or back up first.','Clear Data'],
    ['Logout','Are you sure you want to log out of Spendly?','Logout'],
    ['Delete Account','Deleting your account would permanently remove its profile and financial data. This cannot be undone.','Delete Account']]){
    const p=panel(`Confirmation / ${title}`,null);p.fills=[{type:'SOLID',color:rgb(palette.navy),opacity:0.35}];p.primaryAxisAlignItems='CENTER';
    // Delete and logout dialogs use distinct components and independent actions.
    const dialog=rounded(frame(`Dialog / ${title}`,'VERTICAL',24,18,palette.white));dialog.resize(345,300);dialog.counterAxisSizingMode='FIXED';add(dialog,icon('warning',palette.red,32),text(title==='Logout'?'Log out of Spendly?':`${title}?`,21,'Bold',palette.navy,297),text(message,13,'Regular',palette.muted,297));
    const actions=frame('Dialog actions / Cancel + confirm','HORIZONTAL',0,9);const cancel=button('Cancel',palette.navy,135,true);const destructive=button(confirm,palette.red,153);add(actions,cancel,destructive);dialog.appendChild(actions);p.appendChild(dialog);link(cancel,screens[0]);
    const result=panel(`${title} / Preview notice`,'This prototype demonstrates the confirmation flow. Account services are not connected. No external account is modified.');link(destructive,result);(actionRows.get(title)||[]).forEach(({node})=>link(node,p));
  }
  await Promise.all(links.map(run=>run()));
  figma.currentPage.selection=[screens[0]];figma.viewport.scrollAndZoomIntoView([screens[0]]);
  figma.closePlugin('Created Spendly Settings: editable Auto Layout screens, component variants and prototype flows.');
}
main().catch(error=>figma.closePlugin(`Settings design could not be created: ${error.message}. Check that Inter is available.`));
