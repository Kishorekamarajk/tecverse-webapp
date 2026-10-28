(function(){
const $=s=>document.querySelector(s), $$=s=>Array.from(document.querySelectorAll(s));
const contextPath=((document.body&&document.body.dataset.contextPath)||'').replace(/\/$/,'');
const apiPath=path=>(contextPath==='/'?'':contextPath)+path;
const API={sendMobile:apiPath('/ticket/send-mobile-otp'),verifyMobile:apiPath('/ticket/verify-mobile-otp'),send:apiPath('/ticket/send-otp'),verify:apiPath('/ticket/verify-otp'),detailsStep:apiPath('/ticket/details-step'),register:apiPath('/ticket/register')};
$$('.password-toggle').forEach(button=>button.addEventListener('click',()=>{
 const input=$('#'+button.dataset.passwordTarget);
 const showing=input.type==='password';
 input.type=showing?'text':'password';
 button.setAttribute('aria-label',showing?'Hide password':'Show password');
 button.setAttribute('aria-pressed',String(showing));
 button.innerHTML=`<i class="bi ${showing?'bi-eye-slash':'bi-eye'}" aria-hidden="true"></i>`;
}));
const ministries=[
"Ministry of Agriculture and Farmers Welfare","Ministry of Ayush","Ministry of Chemicals and Fertilizers","Ministry of Civil Aviation",
"Ministry of Coal","Ministry of Commerce and Industry","Ministry of Communications","Ministry of Consumer Affairs, Food and Public Distribution",
"Ministry of Cooperation","Ministry of Corporate Affairs","Ministry of Culture","Ministry of Defence","Ministry of Development of North Eastern Region",
"Ministry of Earth Sciences","Ministry of Education","Ministry of Electronics and Information Technology","Ministry of Environment, Forest and Climate Change",
"Ministry of External Affairs","Ministry of Finance","Ministry of Fisheries, Animal Husbandry and Dairying","Ministry of Food Processing Industries",
"Ministry of Health and Family Welfare","Ministry of Heavy Industries","Ministry of Home Affairs","Ministry of Housing and Urban Affairs",
"Ministry of Information and Broadcasting","Ministry of Jal Shakti","Ministry of Labour and Employment","Ministry of Law and Justice",
"Ministry of Micro, Small and Medium Enterprises","Ministry of Mines","Ministry of Minority Affairs","Ministry of New and Renewable Energy",
"Ministry of Panchayati Raj","Ministry of Parliamentary Affairs","Ministry of Personnel, Public Grievances and Pensions","Ministry of Petroleum and Natural Gas",
"Ministry of Ports, Shipping and Waterways","Ministry of Power","Ministry of Planning","Ministry of Railways","Ministry of Road Transport and Highways",
"Ministry of Rural Development","Ministry of Science and Technology","Ministry of Skill Development and Entrepreneurship","Ministry of Social Justice and Empowerment",
"Ministry of Statistics and Programme Implementation","Ministry of Steel","Ministry of Textiles","Ministry of Tourism",
"Ministry of Tribal Affairs","Ministry of Women and Child Development","Ministry of Youth Affairs and Sports"];
const states=["Andhra Pradesh","Arunachal Pradesh","Assam","Bihar","Chhattisgarh","Goa","Gujarat","Haryana","Himachal Pradesh","Jharkhand","Karnataka","Kerala","Madhya Pradesh","Maharashtra","Manipur","Meghalaya","Mizoram","Nagaland","Odisha","Punjab","Rajasthan","Sikkim","Tamil Nadu","Telangana","Tripura","Uttar Pradesh","Uttarakhand","West Bengal","Andaman and Nicobar Islands","Chandigarh","Dadra and Nagar Haveli and Daman and Diu","Delhi","Jammu and Kashmir","Ladakh","Lakshadweep","Puducherry"];
function populateApplicantStateSelect(){const select=$('#applicantState');if(select)select.innerHTML='<option value="">Select your state or union territory</option>'+states.map(state=>`<option value="${esc(state)}">${esc(state)}</option>`).join('');}
const departments=["General Administration","Finance","Home","Education","Higher Education","School Education","Health and Family Welfare","Industries and Commerce","Information Technology / Electronics","Science and Technology","Agriculture","Animal Husbandry and Fisheries","Co-operation","Rural Development","Urban Development / Municipal Administration","Revenue","Transport","Public Works","Water Resources","Energy","Environment and Forests","Labour and Employment","Skill Development","Tourism and Culture","Social Welfare","Women and Child Development","Tribal Welfare","Food and Civil Supplies","Information and Public Relations","Planning","Law","Personnel","Other"];
let verified=false, emailVerified=false, mobileVerified=false, timer=null, mobileTimer=null, rateLimitTimer=null;

function msg(el,text,ok=false){el.textContent=text;el.className='tr-msg small fw-semibold mt-3 '+(ok?'text-success':'text-danger');}

function setLoading(btn,on,loadingLabel){
  if(!btn)return;
  if(on){
    if(!btn.dataset.label)btn.dataset.label=btn.innerHTML;
    if(!btn.dataset.loadingMarkup)btn.dataset.loadingMarkup=`<span class="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span><span>${loadingLabel||'Please wait…'}</span>`;
    btn.innerHTML=btn.dataset.loadingMarkup;btn.classList.add('is-loading');btn.disabled=true;btn.setAttribute('aria-busy','true');
  } else {
    if(btn.dataset.label)btn.innerHTML=btn.dataset.label;
    btn.classList.remove('is-loading');btn.disabled=false;btn.removeAttribute('aria-busy');btn.removeAttribute('aria-label');
  }
}
function overlay(on,text){const o=$('#trOverlay');if(!o)return;if(!window.bootstrap?.Modal)return;if(text)$('#trOverlayText').textContent=text;const modal=window.bootstrap.Modal.getOrCreateInstance(o);o.dataset.open=on?'1':'';if(on){modal.show();return;}modal.hide();
 // Bootstrap ignores hide() while the fade-in is still running (a fast error response), so hide again once it has opened.
 o.addEventListener('shown.bs.modal',()=>{if(!o.dataset.open)modal.hide();},{once:true});}
function shakeOtp(){$$('#emailOtpInputs input').forEach(i=>{i.classList.remove('tr-shake');void i.offsetWidth;i.classList.add('tr-shake');});}

const STEP_N={verify:1,details:2,preview:3,complete:4};
function show(view){
  const current=$('.tr-view:not([hidden])');
  const target=$(`[data-view="${view}"]`);
  const n=STEP_N[view];
  const fill=$('#progressFill'); if(fill) fill.style.width=((n-1)/3*100)+'%';
  $$('[data-step-dot]').forEach(x=>{
    const d=+x.dataset.stepDot, badge=x.querySelector('b'), completed=d<n, current=d===n;
    x.classList.toggle('active',current);x.classList.toggle('done',completed);
    x.classList.toggle('text-primary',current);x.classList.toggle('text-success',completed);x.classList.toggle('text-secondary',d>n);
    if(badge){
      if(!badge.dataset.label)badge.dataset.label=badge.textContent.trim();
      badge.classList.toggle('bg-primary',current);badge.classList.toggle('bg-success',completed);badge.classList.toggle('bg-white',d>n);
      badge.classList.toggle('text-white',d<=n);badge.classList.toggle('text-secondary',d>n);badge.classList.toggle('border',d>n);
      badge.innerHTML=completed?'<i class="bi bi-check-lg"></i>':badge.dataset.label;
    }
  });
  const swap=()=>{$$('.tr-view').forEach(v=>{v.hidden=true;v.classList.remove('tr-leaving');});target.hidden=false;};
  if(current&&current!==target&&!window.matchMedia('(prefers-reduced-motion: reduce)').matches){
    current.classList.add('tr-leaving');
    setTimeout(swap,180);
  } else swap();
  if (window.gsap) {
    const viewNodes = $$('.tr-view');
    viewNodes.forEach((node) => node.hidden && node.classList.remove('is-visible'));
    if (target) {
      target.hidden = false;
      gsap.fromTo(target, { autoAlpha: 0, y: 18 }, { autoAlpha: 1, y: 0, duration: 0.45, ease: 'power3.out' });
    }
    const progressFill = document.getElementById('progressFill');
    if (progressFill) {
      gsap.fromTo(progressFill, { width: '0%' }, { width: ((n - 1) / 3 * 100) + '%', duration: 0.6, ease: 'power2.out' });
    }
  }
}
function initGsapAnimations(){
  if (!window.gsap) return;
  if (window.ScrollTrigger) {
    gsap.registerPlugin(window.ScrollTrigger);
  }
  gsap.from('.ticket-hero__eyebrow', { y: 24, opacity: 0, duration: 0.7, ease: 'power3.out' });
  gsap.from('.ticket-hero__copy h1, .ticket-hero__text, .ticket-hero__meta, .ticket-hero__cta', {
    y: 28,
    opacity: 0,
    stagger: 0.12,
    duration: 0.8,
    ease: 'power3.out',
    delay: 0.1
  });
  gsap.from('.ticket-hero__visual', {
    x: 40,
    opacity: 0,
    duration: 1,
    ease: 'power3.out',
    delay: 0.2
  });
  gsap.from('.tr-registration-summary, .tr-card', {
    y: 40,
    opacity: 0,
    duration: 0.9,
    stagger: 0.12,
    ease: 'power3.out',
    scrollTrigger: { trigger: '#registration', start: 'top 80%' }
  });
  gsap.from('.tr-step', {
    scale: 0.85,
    opacity: 0,
    duration: 0.35,
    stagger: 0.08,
    ease: 'back.out(1.7)'
  });
}
window.addEventListener('load', initGsapAnimations);
function esc(v){return String(v??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#039;'}[c]));}
function requiredMark(extra){return /(?:^|\\s)required(?:\\s|$)/.test(extra)?' <span class="tr-required-star text-danger" aria-hidden="true">*</span>':'';}
const FIELD_MAX_LENGTH={officialName:150,academiaType:100,collegeName:200,collegeDistrict:100,collegeState:100,universityName:200,academiaRole:100,registerNumber:100,centralMinistry:200,stateName:100,stateDepartment:200,organizationName:200,organizationLocation:255,designation:150,industryOrStartup:100,passportNumber:50,passportValidUntil:10,passportName:150};
const FIELD_PLACEHOLDERS={collegeName:'Enter your institution name',collegeDistrict:'Enter your district',collegeState:'Enter your state or union territory',universityName:'Enter your university name',registerNumber:'Enter your student or staff ID number',organizationName:'Enter your organization name',organizationLocation:'Enter your city or office location',designation:'Enter your designation',industryOrStartup:'Select organization type',passportNumber:'Enter your passport number',passportName:'Enter your full name as shown on your passport'};
const SELECT_PROMPTS={academiaRole:'Select participant role',centralMinistry:'Select a ministry',stateName:'Select a state or union territory',stateDepartment:'Select a department',industryOrStartup:'Select organization type'};
const FREE_TEXT_VALIDATION={
 officialName:{pattern:/^[\p{L}\p{M}][\p{L}\p{M} .,'’\-]{0,149}$/u,message:'Use letters, spaces, periods, apostrophes, commas, or hyphens for your name.'},
 academiaType:{pattern:/^(?=.*\p{L})[\p{L}\p{M}\p{N}][\p{L}\p{M}\p{N} &.,'’()/#+-]{0,99}$/u,message:'Academia type must contain letters.'},
 collegeName:{pattern:/^(?=.*\p{L})[\p{L}\p{M}\p{N}][\p{L}\p{M}\p{N} &.,'’()/#+-]{0,199}$/u,message:'Institution name must contain letters and may include numbers, spaces, and common punctuation (& . , apostrophe - / # + parentheses).'},
 collegeDistrict:{pattern:/^[\p{L}\p{M}][\p{L}\p{M} .,'’()/-]{0,99}$/u,message:'Enter a valid district name using letters and common punctuation.'},
 collegeState:{pattern:/^[\p{L}\p{M}][\p{L}\p{M} .,'’()/-]{0,99}$/u,message:'Enter a valid state or union territory name using letters and common punctuation.'},
 universityName:{pattern:/^(?=.*\p{L})[\p{L}\p{M}\p{N}][\p{L}\p{M}\p{N} &.,'’()/#+-]{0,199}$/u,message:'University name must contain letters and may include numbers, spaces, and common punctuation (& . , apostrophe - / # + parentheses).'},
 registerNumber:{pattern:/^[\p{L}\p{M}\p{N}][\p{L}\p{M}\p{N} _./#-]{0,99}$/u,message:'Student ID may contain letters, numbers, spaces, and these separators: _ . / # -.'},
 organizationName:{pattern:/^(?=.*\p{L})[\p{L}\p{M}\p{N}][\p{L}\p{M}\p{N} &.,'’()/#+-]{0,199}$/u,message:'Organization name must contain letters and may include numbers, spaces, and common punctuation (& . , apostrophe - / # + parentheses).'},
 organizationLocation:{pattern:/^[\p{L}\p{M}][\p{L}\p{M} .,'’()/-]{0,254}$/u,message:'Enter a valid city or office location using letters, spaces, and common punctuation.'},
 organizationLocationOther:{pattern:/^[\p{L}\p{M}][\p{L}\p{M} .,'’()/-]{0,254}$/u,message:'Enter a valid city or office location using letters, spaces, and common punctuation.'},
 designation:{pattern:/^[\p{L}\p{M}][\p{L}\p{M} &.,'’()/-]{0,149}$/u,message:'Designation may contain letters, spaces, and common punctuation (& . , apostrophe - / parentheses).'},
 passportNumber:{pattern:/^[A-Za-z0-9][A-Za-z0-9-]{0,49}$/,message:'Passport number may contain letters, numbers, and hyphens.'},
 passportName:{pattern:/^[\p{L}\p{M}][\p{L}\p{M} .,'’\-]{0,149}$/u,message:'Use letters, spaces, periods, apostrophes, commas, or hyphens for the passport name.'}
};
// Characters each field may NOT contain; they are stripped as the user types or pastes.
const PERSON_NAME_BLOCK=/[^\p{L}\p{M} .,'’-]/gu, PLACE_BLOCK=/[^\p{L}\p{M} .,'’()/-]/gu, ORG_BLOCK=/[^\p{L}\p{M}\p{N} &.,'’()/#+-]/gu;
const INPUT_FILTERS={
 verifyName:PERSON_NAME_BLOCK, officialName:PERSON_NAME_BLOCK, passportName:PERSON_NAME_BLOCK,
 collegeDistrict:PLACE_BLOCK, collegeState:PLACE_BLOCK, organizationLocationOther:PLACE_BLOCK,
 designation:/[^\p{L}\p{M} &.,'’()/-]/gu,
 collegeName:ORG_BLOCK, universityName:ORG_BLOCK, organizationName:ORG_BLOCK, academiaType:ORG_BLOCK,
 registerNumber:/[^\p{L}\p{M}\p{N} _./#-]/gu,
 passportNumber:/[^A-Za-z0-9-]/g,
 phone:/[^0-9+]/g
};
function applyInputFilter(el){
 const block=INPUT_FILTERS[el.name]; if(!block)return;
 let cleaned=el.value.replace(block,'').replace(/^\s+/,'').replace(/\s{2,}/g,' ');
 if(el.name==='passportNumber')cleaned=cleaned.toUpperCase();
 if(el.name==='phone')cleaned=cleaned.replace(/(?!^)\+/g,'');
 if(cleaned===el.value)return;
 const caret=Math.max(0,(el.selectionStart??cleaned.length)-(el.value.length-cleaned.length));
 el.value=cleaned;
 try{el.setSelectionRange(caret,caret);}catch(_){}
}
// Capture phase so the value is cleaned before any field validation listeners run.
document.addEventListener('input',e=>{if(!e.isComposing&&e.target.name)applyInputFilter(e.target);},true);
document.addEventListener('compositionend',e=>{if(e.target.name)applyInputFilter(e.target);},true);
const CITIES=[
 'Agartala','Agra','Ahmedabad','Aizawl','Ajmer','Aligarh','Alappuzha','Amaravati','Amritsar','Anand','Anantapur','Asansol','Ayodhya',
 'Bareilly','Bathinda','Begusarai','Belagavi','Bengaluru','Berhampur','Bharatpur','Bhagalpur','Bhavnagar','Bhilai','Bhopal','Bhubaneswar','Bikaner','Bilaspur','Bokaro',
 'Chandigarh','Chennai','Chhatrapati Sambhajinagar','Coimbatore','Cuttack',
 'Daman','Darjeeling','Davangere','Dehradun','Delhi','Dewas','Dhanbad','Dharamshala','Dibrugarh','Dindigul','Durg','Durgapur',
 'Erode','Faridabad','Gandhinagar','Gangtok','Gaya','Ghaziabad','Gorakhpur','Guntur','Gurugram','Guwahati','Gwalior',
 'Haldwani','Haridwar','Hisar','Hosur','Howrah','Hubballi-Dharwad','Hyderabad','Imphal','Indore','Itanagar','Jabalpur','Jaipur','Jaisalmer','Jalandhar','Jalgaon','Jammu','Jamnagar','Jamshedpur','Jhansi','Jodhpur','Jorhat',
 'Kadapa','Kakinada','Kalaburagi','Kannur','Kanpur','Kanchipuram','Karimnagar','Karnal','Kasaragod','Kharagpur','Kochi','Kohima','Kolhapur','Kolkata','Kollam','Kota','Kottayam','Kozhikode','Kurnool',
 'Leh','Lucknow','Ludhiana','Madurai','Malappuram','Mangaluru','Manali','Margao','Mathura','Meerut','Mirzapur','Mohali','Moradabad','Mumbai','Muzaffarpur','Mysuru',
 'Nagercoil','Nagpur','Nanded','Nashik','Navi Mumbai','Nellore','Nizamabad','Noida',
 'Panaji','Panipat','Pathankot','Patiala','Patna','Puducherry','Pune','Puri','Prayagraj',
 'Raipur','Rajahmundry','Rajkot','Ranchi','Rishikesh','Rohtak','Roorkee','Rourkela',
 'Salem','Sambalpur','Sangli','Satna','Shillong','Shimla','Shivamogga','Siliguri','Silchar','Sikar','Solapur','Srinagar','Surat',
 'Thanjavur','Thane','Thiruvananthapuram','Thoothukudi','Thrissur','Tiruchirappalli','Tirunelveli','Tiruppur','Tirupati','Udaipur','Ujjain','Vadodara','Varanasi','Vasco da Gama','Vellore','Vijayawada','Visakhapatnam','Warangal'
].sort((a,b)=>a.localeCompare(b));
function field(label,name,type='text',extra=''){const maxLength=FIELD_MAX_LENGTH[name],placeholder=FIELD_PLACEHOLDERS[name];return `<label class="col-12 col-md-6 mb-3 fw-semibold text-[#07182F]">${label}${requiredMark(extra)}<input class="form-control mt-2 rounded-3 border-secondary-subtle py-3" name="${name}" type="${type}" ${maxLength?`maxlength="${maxLength}"`:''} ${placeholder?`placeholder="${placeholder}"`:''} ${extra}></label>`}
function select(label,name,opts,extra=''){return `<label class="col-12 col-md-6 mb-3 fw-semibold text-[#07182F]">${label}${requiredMark(extra)}<select class="form-select mt-2 rounded-3 border-secondary-subtle" name="${name}" ${extra}><option value="">${SELECT_PROMPTS[name]||'Select an option'}</option>${opts.map(o=>`<option value="${esc(o)}">${esc(o)}</option>`).join('')}</select></label>`}
function cityField(){return `<div class="col-12 col-md-6 mb-3 fw-semibold text-[#07182F]"><label for="organizationLocationChoice">City / office location${requiredMark('required')}</label><select id="organizationLocationChoice" class="form-select mt-2 rounded-3 border-secondary-subtle" name="organizationLocationChoice" required><option value="">Select a city</option>${CITIES.map(city=>`<option value="${esc(city)}">${esc(city)}</option>`).join('')}<option value="__OTHER__">Other</option></select><div id="organizationLocationOtherWrap" class="mt-3" hidden><label for="organizationLocationOther">Enter city / office location</label><input id="organizationLocationOther" class="form-control mt-2 rounded-3 border-secondary-subtle py-3" name="organizationLocationOther" type="text" maxlength="255" placeholder="Enter your city or office location" disabled></div></div>`}
function renderConditional(){
 const cat=$('#category').value, box=$('#conditional'); let h='';
 if(cat==='ACADEMIA'){
  h='<div class="small fw-bold text-primary text-uppercase border-bottom pb-2 mb-3">Academia</div><div class="tr-grid row">';
  h+=select('Participant role','academiaRole',['Student','Professor / Faculty','Research Scholar'],'required');
  h+=field('Institution name','collegeName','text','list="collegeList" required');
  h+='<datalist id="collegeList"><option value="Anna University"><option value="Indian Institute of Technology Madras"><option value="University of Delhi"><option value="Indian Institute of Science"><option value="Amrita Vishwa Vidyapeetham"></datalist>';
  h+=field('District','collegeDistrict','text','required');
  h+=field('University / affiliating institution','universityName','text','required');
  h+='</div>';
 } else if(cat==='CENTRAL_GOVERNMENT'){
  h='<div class="small fw-bold text-primary text-uppercase border-bottom pb-2 mb-3">Central Government</div><div class="tr-grid row">';
  h+=select('Ministry / department','centralMinistry',ministries,'required')+field('Organization / office name','organizationName','text','required');
  h+=field('Designation / job title','designation','text','required')+cityField()+'</div>';
 } else if(cat==='STATE_GOVERNMENT'){
  h='<div class="small fw-bold text-primary text-uppercase border-bottom pb-2 mb-3">State Government</div><div class="tr-grid row">';
  h+=select('Department','stateDepartment',departments,'required');
  h+=field('Organization / office name','organizationName','text','required')+field('Designation / job title','designation','text','required');
  h+=cityField()+'</div>';
 } else if(cat==='INDUSTRY_STARTUP'){
  h='<div class="small fw-bold text-primary text-uppercase border-bottom pb-2 mb-3">Industry / Startup</div><div class="tr-grid row">';
  h+=select('Organization type','industryOrStartup',['Startup','Mid-sized Company','MNC','Industry / Enterprise'],'required')+field('Organization name','organizationName','text','required');
  h+=cityField()+field('Designation / job title','designation','text','required')+'</div>';
 } else if(['VIP_SPECIAL_INVITEE','SPEAKER','ORGANIZER'].includes(cat)){
  const labels={VIP_SPECIAL_INVITEE:'VIP / Special Invitee',SPEAKER:'Speaker',ORGANIZER:'Organizer'};
  h=`<div class="small fw-bold text-primary text-uppercase border-bottom pb-2 mb-3">${labels[cat]}</div>`;
 }
 box.innerHTML=h;
}
function updateAcademiaRoleFields(){
 const role=$('#conditional [name="academiaRole"]')?.value;
 const idField=$('#conditional [name="registerNumber"]');
 if(role==='Student'&&!idField){
  const holder=document.createElement('div');
  holder.innerHTML=field('Student ID number','registerNumber','text','required');
  $('#conditional .tr-grid').appendChild(holder.firstElementChild);
 } else if(role!=='Student'&&idField){
  idField.closest('label')?.remove();
 }
}
function renderPassport(){
 const c=$('#citizenship').value, box=document.querySelector('#conditional .tr-passport');
 if(c==='FOREIGNER'){
  if(!box){const d=document.createElement('div');d.className='tr-passport';d.innerHTML='<div class="small fw-bold text-primary text-uppercase border-bottom pb-2 mb-3">Passport details</div><div class="tr-grid row">'+field('Passport number','passportNumber','text','required')+field('Passport expiry date','passportValidUntil','date','required')+field('Full name as shown on passport','passportName','text','required')+'</div>';$('#conditional').appendChild(d);}
 } else if(box) box.remove();
}
function collect(){
 const fd=new FormData($('#detailsForm')); const o=Object.fromEntries(fd.entries());if(o.organizationLocationChoice){o.organizationLocation=o.organizationLocationChoice==='__OTHER__'?(o.organizationLocationOther||'').trim():o.organizationLocationChoice;delete o.organizationLocationChoice;delete o.organizationLocationOther;}o.email=$('#email').value.trim().toLowerCase();o.phone=$('#phone').value.trim();o.officialName=$('#verifyName').value.trim();
  if(o.category==='STATE_GOVERNMENT')o.stateName=o.applicantState;
  if(o.category==='ACADEMIA')o.collegeState=o.applicantState;
 o.password=$('#password').value; o.confirmPassword=$('#confirmPassword').value;
 o.attendanceDays=fd.getAll('attendanceDays'); return o;
}
function validateTicketFields(form){
 let valid=true, firstInvalid=null;
 form.querySelectorAll('input,select,textarea').forEach(el=>{
  if(el.type==='checkbox'||el.type==='file'||el.type==='button'||el.type==='submit')return;
  el.setCustomValidity('');
  const value=el.value.trim();
  if(el.required&&!value)el.setCustomValidity(el.name==='academiaRole'?'Select your participant role: Student, Professor / Faculty, or Research Scholar.':'This field is required.');
  else if(el.name==='email'&&value&&!el.validity.valid)el.setCustomValidity('Enter a valid email address.');
  else if(el.name==='phone'&&value&&!/^(?:\+91[-\s]?)?[6-9]\d{9}$/.test(value))el.setCustomValidity('Enter a valid 10-digit Indian mobile number.');
  else if(el.name==='password'&&(value.length<8||value.length>64||!/[A-Z]/.test(value)||!/[0-9]/.test(value)||!/[\u0021-\u002f\u003a-\u0040\u005b-\u0060\u007b-\u007e]/.test(value)))el.setCustomValidity('Use 8–64 characters with at least one uppercase letter, one number, and one special symbol.');
  else if(el.name==='confirmPassword'&&value!==$('#password').value)el.setCustomValidity('Password and confirm password must match.');
  else if(el.name==='officialName'&&value.length>150)el.setCustomValidity('Name must be 150 characters or fewer.');
  else if(value&&FREE_TEXT_VALIDATION[el.name]&&!FREE_TEXT_VALIDATION[el.name].pattern.test(value))el.setCustomValidity(FREE_TEXT_VALIDATION[el.name].message);
  const ok=el.checkValidity();
  el.setAttribute('aria-invalid',String(!ok));
  if(!ok){valid=false;firstInvalid ||= el;}
 });
 if(!valid){firstInvalid.reportValidity();firstInvalid.focus();}
 return valid;
}
function preview(){
 const o=collect(); const labels={category:'Registration category',officialName:'Full name',email:'Email address',phone:'Mobile number',citizenshipStatus:'Citizenship / residency status',applicantState:'State / Union Territory',academiaType:'Academia type',collegeName:'Institution',collegeDistrict:'District',universityName:'University',academiaRole:'Participant role',registerNumber:'Student / staff ID number',centralMinistry:'Ministry / department',stateName:'Government state / union territory',stateDepartment:'Department',organizationName:'Organization / office',organizationLocation:'City / office location',designation:'Designation / job title',industryOrStartup:'Organization type',passportNumber:'Passport number',passportValidUntil:'Passport expiry date',passportName:'Name as shown on passport'};
 $('#preview').innerHTML=Object.entries(labels).filter(([k])=>o[k]).map(([k,l])=>`<div class="col-12 col-md-6 border-bottom p-3"><span class="small text-secondary text-uppercase">${esc(l)}</span><strong class="d-block mt-1 fw-semibold text-[#07182F]">${esc(o[k])}</strong></div>`).join('')+`<div class="col-12 col-md-6 border-bottom p-3"><span class="small text-secondary text-uppercase">Participation Preference</span><strong class="d-block mt-1 fw-semibold text-[#07182F]">${esc(o.attendanceDays.join(', '))}</strong></div>`;
 window.ticketPayload=o; show('preview');
}
async function post(url,data){const r=await fetch(url,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(data)});const j=await r.json().catch(()=>({}));if(!r.ok){const error=new Error(j.message||j.error||'Request failed');error.status=r.status;error.retryAfter=Number(r.headers.get('Retry-After'))||0;throw error;}return j;}

$('#sendOtp').onclick=async()=>{
 if(window.jQuery && !window.jQuery('#ticketVerifyForm').valid())return;
 const btn=$('#sendOtp'); const name=$('#verifyName').value.trim(),email=$('#email').value.trim(),phone=$('#phone').value.trim(),password=$('#password').value,confirmPassword=$('#confirmPassword').value,m=$('#verifyMsg'),otpMessage=$('#otpBox').hidden?m:$('#emailOtpMsg');
 if(!name||!email||!phone||!password||!confirmPassword){msg(m,'Enter your name, email, phone number, and password.');return;}
 if(!/^[\p{L}\p{M}][\p{L}\p{M} .,'’\-]{1,149}$/u.test(name)){msg(m,'Use letters, spaces, periods, apostrophes, commas, or hyphens for your name.');return;}
 if(!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)){msg(m,'Enter a valid email address.');return;}
 if(!/^(?:\+91[-\s]?)?[6-9]\d{9}$/.test(phone)){msg(m,'Enter a valid 10-digit Indian mobile number.');return;}
 if(password.length>64){msg(m,'Password must be 64 characters or fewer.');return;}
 if(password.length<8||!/[A-Z]/.test(password)||!/[0-9]/.test(password)||!/[\u0021-\u002f\u003a-\u0040\u005b-\u0060\u007b-\u007e]/.test(password)){
  msg(m,'Use 8–64 characters with at least one uppercase letter, one number, and one special symbol.');return;
 }
 if(password!==confirmPassword){msg(m,'Password and confirm password must match.');return;}
 if(emailVerified)return;
 let retryAfterSeconds=0;
 setLoading(btn,true);
 try{await post(API.send,{fullName:name,email,phone,passType:'Tec-Verse 2026 Ticket'});$('#otpEmail').textContent=email;$('#otpBox').hidden=false;msg($('#emailOtpMsg'),'OTP request accepted. Check your email shortly.',true);m.textContent='';startTimer();$$('#emailOtpInputs input')[0]?.focus();}
 catch(e){msg(otpMessage,e.message);if(e.status===429)retryAfterSeconds=e.retryAfter||60;}
 finally{setLoading(btn,false);if(retryAfterSeconds)startRateLimitCountdown(btn,retryAfterSeconds,otpMessage);}
};
function startTimer(){let n=60;$('#resendOtp').disabled=true;clearInterval(timer);timer=setInterval(()=>{n--;$('#resendOtp').textContent=n>0?`Resend OTP (${n}s)`:'Resend OTP';if(n<=0){clearInterval(timer);$('#resendOtp').disabled=false;}},1000);$('#resendOtp').textContent='Resend OTP (60s)';}
function startRateLimitCountdown(button,seconds,message=$('#verifyMsg')){
 let remaining=Math.max(1,seconds);
 clearInterval(rateLimitTimer);
 const originalLabel=button.dataset.label||button.innerHTML;
 const update=()=>{
  button.disabled=remaining>0;
  button.textContent=remaining>0?`Please wait (${remaining}s)`:originalLabel.replace(/<[^>]*>/g,'').trim();
  message.textContent=remaining>0?`Too many requests. Please wait ${remaining} seconds before trying again.`:'You can request an OTP again now.';
  message.className='tr-msg small fw-semibold mt-3 '+(remaining>0?'text-danger':'text-success');
 };
 update();
 rateLimitTimer=setInterval(()=>{remaining--;update();if(remaining<=0){clearInterval(rateLimitTimer);button.innerHTML=originalLabel;}},1000);
}
$('#resendOtp').onclick=()=>$('#sendOtp').click();
$('#registerStart').onclick=()=>{
 if(window.jQuery && !window.jQuery('#ticketVerifyForm').valid())return;
 if(!emailVerified){
  const missing=[];
  if(!emailVerified)missing.push('email');
  if(!mobileVerified)missing.push('mobile');
  msg($('#verifyMsg'),`Please verify your ${missing.join(' and ')} OTP${missing.length>1?'s':''} before registering.`);
  return;
 }
 proceedAfterVerification();
};
$('#sendMobileOtp').onclick=async()=>{
 if(mobileVerified)return;
 const btn=$('#sendMobileOtp'),phone=$('#phone').value.trim(),m=$('#verifyMsg'),otpMessage=$('#mobileOtpBox').hidden?m:$('#mobileOtpMsg');
 if(!/^(?:\+91[-\s]?)?[6-9]\d{9}$/.test(phone)){msg(m,'Enter a valid 10-digit Indian mobile number.');return;}
 let retryAfterSeconds=0;
 setLoading(btn,true,'Sending…');
 try{await post(API.sendMobile,{phone});$('#otpMobile').textContent=phone;$('#mobileOtpBox').hidden=false;$$('#mobileOtpInputs input').forEach(i=>{i.value='';});msg($('#mobileOtpMsg'),'OTP sent to your mobile number by SMS.',true);m.textContent='';startMobileTimer();$$('#mobileOtpInputs input')[0]?.focus();}
 catch(e){msg(otpMessage,e.message);if(e.status===429)retryAfterSeconds=e.retryAfter||60;}
 finally{setLoading(btn,false);if(retryAfterSeconds)startRateLimitCountdown(btn,retryAfterSeconds,otpMessage);}
};
function startMobileTimer(){let n=60;const b=$('#resendMobileOtp');b.disabled=true;clearInterval(mobileTimer);mobileTimer=setInterval(()=>{n--;b.textContent=n>0?`Resend OTP (${n}s)`:'Resend OTP';if(n<=0){clearInterval(mobileTimer);b.disabled=false;}},1000);b.textContent='Resend OTP (60s)';}
$('#resendMobileOtp').onclick=()=>$('#sendMobileOtp').click();
$('#verifyMobileOtp').onclick=async()=>{
 const btn=$('#verifyMobileOtp'),otp=$$('#mobileOtpInputs input').map(x=>x.value).join(''),m=$('#mobileOtpMsg');
 if(otp.length!==6){msg(m,'Enter the complete 6-digit OTP sent to your mobile.');return;}
 let retryAfterSeconds=0;
 setLoading(btn,true);
 try{await post(API.verifyMobile,{phone:$('#phone').value.trim(),otp});mobileVerified=true;if(!emailVerified)msg(m,'Mobile number verified. Now click Send OTP next to your email to verify it.',true);}
 catch(e){msg(m,e.message);if(e.status===429)retryAfterSeconds=e.retryAfter||60;}
 finally{setLoading(btn,false);if(retryAfterSeconds)startRateLimitCountdown(btn,retryAfterSeconds,m);}
 if(mobileVerified)setMobileVerifiedUi(true);
};
function setMobileVerifiedUi(on){
 const b=$('#sendMobileOtp');
 $('#phone').readOnly=on;$('#mobileOtpBox').hidden=true;clearInterval(mobileTimer);
 b.disabled=on;b.innerHTML=on?'<i class="bi bi-check-circle-fill"></i> Verified':'Verify Mobile';delete b.dataset.label;
}
// Six single-digit boxes per OTP: auto-advance, paste-to-fill, backspace/arrow navigation, Enter submits.
function wireOtpBoxes(container,submitButton){
const otpInputs=$$(container+' input');
otpInputs.forEach((input,index)=>{
 input.autocomplete=index===0?'one-time-code':'off';
 input.oninput=()=>{
  const digits=input.value.replace(/\D/g,'');
  if(digits.length>1){
   [...digits].slice(0,otpInputs.length-index).forEach((digit,offset)=>{otpInputs[index+offset].value=digit;});
   otpInputs[Math.min(index+digits.length,otpInputs.length)-1].focus();
  }else{
   input.value=digits;
   if(digits&&otpInputs[index+1])otpInputs[index+1].focus();
  }
 };
 input.onkeydown=event=>{
  if(event.key==='Backspace'){
   if(input.value){input.value='';event.preventDefault();}
   else if(otpInputs[index-1]){otpInputs[index-1].focus();otpInputs[index-1].value='';event.preventDefault();}
  }else if(event.key==='Delete'&&input.value){input.value='';event.preventDefault();}
  else if(event.key==='ArrowLeft'&&otpInputs[index-1]){otpInputs[index-1].focus();event.preventDefault();}
  else if(event.key==='ArrowRight'&&otpInputs[index+1]){otpInputs[index+1].focus();event.preventDefault();}
  else if(event.key==='Enter'){event.preventDefault();$(submitButton).click();}
 };
});
}
wireOtpBoxes('#emailOtpInputs','#verifyOtp');
wireOtpBoxes('#mobileOtpInputs','#verifyMobileOtp');
$('#verifyOtp').onclick=async()=>{
 const btn=$('#verifyOtp'); const otp=$$('#emailOtpInputs input').map(x=>x.value).join(''),m=$('#emailOtpMsg');
 if(otp.length!==6){msg(m,'Enter the complete 6-digit OTP.');shakeOtp();return;}
 let retryAfterSeconds=0;
 setLoading(btn,true);
 try{
  await post(API.verify,{email:$('#email').value.trim(),otp});
  emailVerified=true;
  msg(m,'Email verified successfully. You can continue.',true);
 }
 catch(e){msg(m,e.message);shakeOtp();if(e.status===429)retryAfterSeconds=e.retryAfter||60;}
 finally{setLoading(btn,false);if(retryAfterSeconds)startRateLimitCountdown(btn,retryAfterSeconds,m);}
 if(emailVerified)setEmailVerifiedUi(true);
};
const sendOtpLabel=$('#sendOtp').innerHTML;
function setEmailVerifiedUi(on){
 const b=$('#sendOtp');
 $('#email').readOnly=on;$('#otpBox').hidden=true;clearInterval(timer);
 b.disabled=on;b.innerHTML=on?'<i class="bi bi-check-circle-fill"></i> Verified':sendOtpLabel;delete b.dataset.label;
}
// Runs once both email and mobile OTPs are verified.
async function proceedAfterVerification(){
 const m=$('#verifyMsg');
 // The server confirms email verification; mobile OTP is temporarily optional.
 if(!await loadDetailsStep()){msg(m,'Email OTP verification could not be confirmed. Please verify again.');emailVerified=false;setEmailVerifiedUi(false);return;}
 verified=true;
 const verifiedName=$('#verifyName').value.trim();
 $('#detailsForm [name="officialName"]').value=verifiedName;
 $('#verifyName').readOnly=true;
 $('#email').readOnly=true;
 $('#phone').readOnly=true;
 $('#detailsForm [name="officialName"]').readOnly=true;
 msg(m,'Email verified successfully. Your verified name, email, and phone number are locked.',true);
 show('details');
}
async function loadDetailsStep(){
 let r;
 try{r=await fetch(API.detailsStep,{headers:{Accept:'text/html'},cache:'no-store'});}catch(_){return false;}
 if(!r.ok)return false;
 if($('#detailsForm'))return true; // already loaded earlier; keep what the user has typed
 const doc=new DOMParser().parseFromString(await r.text(),'text/html'), form=doc.querySelector('form#detailsForm[data-view="details"]');
 if(!form)return false;
 $('#detailsStepHost').replaceChildren(document.adoptNode(form));
 populateApplicantStateSelect();
 bindDetailsStep();
 window.TecverseValidation?.init($('#detailsForm'));
 return true;
}
function bindDetailsStep(){
$('#category').onchange=()=>{renderConditional();renderPassport();};$('#citizenship').onchange=renderPassport;
document.querySelector('#conditional').addEventListener('change',e=>{if(e.target.name==='academiaRole')updateAcademiaRoleFields();if(e.target.name==='organizationLocationChoice'){const other=e.target.value==='__OTHER__',wrap=$('#organizationLocationOtherWrap'),input=$('#organizationLocationOther');if(wrap&&input){wrap.hidden=!other;input.disabled=!other;input.required=other;if(!other)input.value='';}}});
document.querySelector('#conditional').addEventListener('input',e=>{const rule=FREE_TEXT_VALIDATION[e.target.name];if(!rule)return;const value=e.target.value.trim();e.target.setCustomValidity(value&&!rule.pattern.test(value)?rule.message:'');if(e.target.hasAttribute('aria-invalid'))e.target.setAttribute('aria-invalid',String(!e.target.validity.valid));});
$('#backVerify').onclick=()=>show('verify');
$('#detailsForm').onsubmit=e=>{e.preventDefault();const days=$$('input[name="attendanceDays"]:checked');const m=$('#detailsMsg');if(!validateTicketFields(e.currentTarget))return;if(!$('#category').value){msg(m,'Choose your registration type.');return;}if(!days.length){msg(m,'Select Day 1, Day 2, or Both Days.');return;}if(days.length>1){msg(m,'Choose only one option: Day 1, Day 2, or Both Days.');days[0].focus();return;}preview();};
$$('input[name="attendanceDays"]').forEach(input=>input.addEventListener('change',()=>{
 if(!input.checked)return;
 $$('input[name="attendanceDays"]').forEach(other=>{if(other!==input)other.checked=false;});
}));
}
$('#editForm').onclick=()=>show('details');
const categoryLabels={ACADEMIA:'Academia',CENTRAL_GOVERNMENT:'Central Government',STATE_GOVERNMENT:'State Government',INDUSTRY_STARTUP:'Industry / Startup',VIP_SPECIAL_INVITEE:'VIP / Special Invitee',SPEAKER:'Speaker',ORGANIZER:'Organizer'};
const dayLabels={DAY_1:'Day 1 · 26 Nov',DAY_2:'Day 2 · 27 Nov',BOTH:'Both Days · 26 & 27 Nov'};

function renderRefDigits(ref){
 const box=$('#referenceNumber'); box.innerHTML='';
 String(ref||'').split('').forEach((ch,i)=>{
  const s=document.createElement('span'); s.textContent=ch;
  s.style.animationDelay=(0.55+i*0.045)+'s';
  box.appendChild(s);
 });
}

function showRegistrationCelebration(){
 document.querySelector('[data-registration-celebration]')?.remove();
 const popup=document.createElement('div');
 popup.dataset.registrationCelebration='';
 popup.setAttribute('role','dialog');
 popup.setAttribute('aria-modal','true');
 popup.setAttribute('aria-labelledby','registrationCelebrationTitle');
 popup.style.cssText='position:fixed;inset:0;display:grid;place-items:center;padding:24px;background:rgba(8,18,35,.68);backdrop-filter:blur(5px);z-index:2147483000';
 const card=document.createElement('div');
 card.style.cssText='width:min(440px,100%);padding:36px 28px;border-radius:24px;background:#fff;color:#12213a;text-align:center;box-shadow:0 24px 80px rgba(0,0,0,.35);font-family:system-ui,sans-serif';
 const icon=document.createElement('div');
 icon.textContent='\u{1F389}';
 icon.style.cssText='font-size:56px;line-height:1;margin-bottom:18px';
 const title=document.createElement('h2');
 title.id='registrationCelebrationTitle';
 title.textContent='Registration successful!';
 title.style.cssText='margin:0 0 10px;font-size:26px;font-weight:800';
 const message=document.createElement('p');
 message.textContent='Your registration has been submitted. We look forward to seeing you at Tec-Verse 2026.';
 message.style.cssText='margin:0 0 24px;color:#536174;font-size:16px;line-height:1.5';
 const close=document.createElement('button');
 close.type='button';
 close.textContent='Continue';
 close.style.cssText='border:0;border-radius:12px;padding:12px 28px;background:#f97316;color:#fff;font-size:16px;font-weight:700;cursor:pointer';
 const dismiss=()=>{popup.remove();if(typeof window.celebrateRegistration==='function')window.celebrateRegistration();};
 close.addEventListener('click',dismiss);
 popup.addEventListener('click',event=>{if(event.target===popup)dismiss();});
 card.append(icon,title,message,close);
 popup.appendChild(card);
 document.body.appendChild(popup);
 close.focus();
}

function launchIdCard(data,payload){
 renderRefDigits(data.referenceNumber);
 const fullName=(payload&&payload.officialName)||'YOUR NAME';
 const designation=(payload&&typeof payload.designation==='string'?payload.designation:'').trim();
 const category=(payload&&payload.category)||'';
 const organization=(payload&&payload.organizationName)
  || (category==='ACADEMIA'&&payload&&payload.universityName)
  || (category==='ACADEMIA'&&payload&&payload.collegeName)
  || (category==='CENTRAL_GOVERNMENT'&&payload&&payload.centralMinistry)
  || (category==='STATE_GOVERNMENT'&&payload&&payload.stateDepartment)
  || 'Organization / Institution';
 const categoryKey=category || 'INDUSTRY_STARTUP';
 const badgeText=(categoryLabels[categoryKey] || 'Delegate').trim();
 const safeName=fullName.trim()||'YOUR NAME';
 $('#cardName').textContent=safeName.toUpperCase();
 const designationNode=$('#cardDesignation');
 designationNode.textContent=designation;
 designationNode.hidden=!designation;
 const organizationNode=$('#cardOrganization');
 organizationNode.textContent=(organization||'').trim();
 organizationNode.hidden=!organizationNode.textContent;
 $('#cardCategory').innerHTML=`<span>${esc(badgeText)}</span>`;
 const qr=$('#cardQr'), qrError=$('#cardQrError');
 qr.hidden=false;
 qrError.hidden=true;
 qr.onerror=()=>{qr.hidden=true;qrError.hidden=false;};
 qr.onload=()=>{qr.hidden=false;qrError.hidden=true;};
 qr.src=apiPath('/ticket/qr')+'?token='+encodeURIComponent(data.scanToken);
 const card=$('#idCard');
 card.classList.remove('is-in'); void card.offsetWidth;
 card.classList.add('is-in');
}

$('#submitFinal').onclick=async()=>{
 const btn=$('#submitFinal'); const m=$('#previewMsg');
 if(!verified){msg(m,'Email verification is required.');show('verify');return;}
 if(!validateTicketFields($('#detailsForm'))){show('details');return;}
 if(!window.ticketPayload?.attendanceDays?.length){msg(m,'Select at least one participation day.');show('details');return;}
 setLoading(btn,true); overlay(true,'Submitting your registration…');
 try{const result=await post(API.register,window.ticketPayload);const data=result.data||result,status=$('#confirmationEmailStatus');$('#completeEmail').textContent=data.email;status.textContent=data.confirmationEmailSent?status.dataset.emailSent:status.dataset.emailPending;show('complete');showRegistrationCelebration();launchIdCard(data,window.ticketPayload);}
 catch(e){if(e.status===403){verified=false;emailVerified=false;setEmailVerifiedUi(false);setMobileVerifiedUi(false);['#verifyName','#email','#phone'].forEach(s=>{$(s).readOnly=false;});show('verify');msg($('#verifyMsg'),e.message);return;}msg(m,e.message);}
 finally{setLoading(btn,false);overlay(false);}
};


})();
