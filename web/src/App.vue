<script setup>
import { ref } from 'vue';
import XLSXReader from './components/XLSXReader.vue';
import axios from 'axios';
import { coe_helper } from './utils/coe_helper';
import mermaid from 'https://cdn.jsdelivr.net/npm/mermaid@9/dist/mermaid.esm.min.mjs';
window.mermaid = mermaid;

// init SFC objects
const cXLSXReader = ref(null);
const cLoaderPanel = ref(null);

// for flags
const flag_is_generating = ref(false);

// for results
const pma = ref(null);

const mermaid_chart_rob = ref(null);
const mermaid_chart_pbb = ref(null);
const mermaid_chart_inc = ref(null);
const mermaid_chart_imp = ref(null);
const mermaid_chart_ind = ref(null);

const params = ref({
    measure_of_effect: {
        value: 'OR',
        disabled: false,
        type: 'select',
        options: [
            {text: 'Odds Ratio', value: 'OR'},
            {text: 'Risk Ratio', value: 'RR'},
            {text: 'Risk Difference', value: 'RD'},
        ],
        title: "Measure of Effect",
        description: "The measure of effect. Available values include: OR, RR, or RD."
    },

    imp_t: {
        value: '0',
        disabled: true,
        type: 'input',
        title: "Imprecision T",
        description: "The threshold for imprecision evaluation. It's optional. Default value is 0."
    },
});


function get_params() {
    let p = {};
    for (const key in params.value) {
        p[key] = params.value[key].value;
    }

    return p;
}

// functions
function on_click_submit() {
  const rs = cXLSXReader.value.get_rs();
  console.log('* got rs', rs);

  if (rs.length == 0) {
    return;
  }

  const cfg = get_params();
  console.log("* got cfg", cfg);

  // disable all buttons
  flag_is_generating.value = true;

  get_coe(rs, cfg);
}

async function get_coe(rs, cfg) {
  const formData = new FormData();
  formData.append('rs', JSON.stringify(rs));
  formData.append('am', 'FORESTDATA');
  formData.append('sm', cfg.measure_of_effect);
  formData.append('imp_t', cfg.imp_t);
  formData.append('hk', 'FALSE');
  formData.append('apikey', '7323590e-577b-4f46-b19f-3ec402829bd6');
  try {
    const data = await axios.post(
      'https://workspace.network-meta-analysis.com/rplt/PWMA_PRCM_COE',
      formData
    );

    draw_coe_data(data.data);

  } catch (error) {
    console.log(error);
  }

  // ok, enable all buttons
  flag_is_generating.value = false;
}

function draw_coe_data(data) {
  console.log("* coe return:", data);
  
  // set pma
  pma.value = data;

  // update charts
  show_coe('rob');
  show_coe('inc');
  show_coe('pbb');
  show_coe('imp');
  show_coe('ind');
}

function to_percentage(v) {
  if (isNaN(v)) {
    return 'NA';
  }

  return (v * 100).toFixed(2) + '%';
}

function show_coe(chart_name) {
  let chart_desc = '';
  switch (chart_name) {
    case 'rob':
      chart_desc = coe_helper.get_rob_mermaid(
        pma.value.data.coe.info.risk_of_bias
      );
      mermaid.render(
        chart_name + '_flowchart',
        chart_desc,
        (svg_code) => {
          mermaid_chart_rob.value = svg_code;
        }
      );
      break;

    case 'inc':
      chart_desc = coe_helper.get_inc_mermaid(
        pma.value.data.coe.info.inconsistency
      );
      mermaid.render(
        chart_name + '_flowchart',
        chart_desc,
        (svg_code) => {
          mermaid_chart_inc.value = svg_code;
        }
      );
      break;

    case 'pbb':
      chart_desc = coe_helper.get_pbb_mermaid(
        pma.value.data.coe.info.publication_bias
      );
      mermaid.render(
        chart_name + '_flowchart',
        chart_desc,
        (svg_code) => {
          mermaid_chart_pbb.value = svg_code;
        }
      );
      break;

    case 'imp':
      chart_desc = coe_helper.get_imp_mermaid(
        pma.value.data.coe.info.imprecision
      );
      mermaid.render(
        chart_name + '_flowchart',
        chart_desc,
        (svg_code) => {
          mermaid_chart_imp.value = svg_code;
        }
      );
      break;

    case 'ind':
      chart_desc = coe_helper.get_ind_mermaid(
        pma.value.data.coe.info.indirectness
      );
      mermaid.render(
        chart_name + '_flowchart',
        chart_desc,
        (svg_code) => {
          mermaid_chart_ind.value = svg_code;
        }
      );
  }

}

async function demo_sample_data() {
  await cXLSXReader.value.load_sample_data();
  // submit
  on_click_submit();
}
</script>

<template>
<div id="input_panel">
  <div class="header">
    Visual Explanation of Certainty of Evidence Assessment
  </div>
  <div class="param_panel">
    <button @click="demo_sample_data()"
      :disabled="flag_is_generating"
      style="margin-right: 2em;">
      <template v-if="flag_is_generating">
        <i class="fa fa-spinner fa-spin"></i>
      </template>
      <template v-else>
        <i class="fa fa-upload"></i>
      </template>
      Generate Visual Explanation for Sample Data
    </button>

    <XLSXReader ref="cXLSXReader"></XLSXReader>
  
    <div class="paramter-box">
  
      <div v-for="param in params"
          class="param-item">
          <template v-if="param.disabled">

          </template>
          <template v-else>
            <div class="item-label">
              <label>
                  {{ param.title }}
              </label>
            </div>
            <div v-if="param.type == 'input'"
                  class="item-value">
                  <input type="text" 
                      v-model="param.value" 
                      v-bind:disabled="param.disabled">
                  <!-- <p class="item-desc">
                      {{ param.description }}
                  </p> -->
              </div>

              <div v-else-if="param.type == 'select'"
                  class="item-value">
                  <select v-model="param.value" 
                      v-bind:disabled="param.disabled">
                      <option v-for="option in param.options"
                          v-bind:value="option.value">
                          {{ option.text }}
                      </option>
                  </select>
                  <!-- <p class="item-desc">
                      {{ param.description }}
                  </p> -->
              </div>
          </template>
      </div>


    </div>

    <button @click="on_click_submit"
      :disabled="flag_is_generating"
      style="margin-left: 1em;">
      <template v-if="flag_is_generating">
        <i class="fa fa-spinner fa-spin"></i>
        Generating...
      </template>
      <template v-else>
        <i class="fa fa-cogs"></i>
        Generate Visual Explanation
      </template>
    </button>

    
  </div>

</div>


<div id="result_panel">
  <div class="box">
    <div class="box-header">
      <i class="fa fa-table"></i>
      Pairwise Meta-analysis Results
    </div>
    <div class="box-body">
      <table v-if="pma != null"
        class="ma-table"
        style="margin-bottom: 3em;">
        <tr>
            <th>Study</th>
            <th>Year</th>
            <th>Et</th>
            <th>Nt</th>
            <th>Ec</th>
            <th>Nc</th>
            <th>Risk of Bias</th>
            <th>Indirectness</th>
            <th>{{ pma.params.measure_of_effect }}</th>
            <th>Weight</th>
        </tr>
        <tr v-for="r in pma.data.primma.stus">
            <td>{{ r.name }}</td>
            <td>{{ r.year }}</td>
            <td>{{ r.Et }}</td>
            <td>{{ r.Nt }}</td>
            <td>{{ r.Ec }}</td>
            <td>{{ r.Nc }}</td>
            <td>{{ coe_helper.val_to_label(r.rob, 'risk_of_bias') }}</td>
            <td>{{ coe_helper.val_to_label(r.ind, 'indirectness') }}</td>
            <td>
                {{ r.bt_TE }}
                (
                    {{ r.bt_lower }};
                    {{ r.bt_upper }}
                )
            </td>
            <td>{{ to_percentage(r.w_random) }}</td>
        </tr>

        <!-- MA Result -->
        <tr>
            <td colspan="2">
                <b>
                  Random Effect Model:
                </b>
            </td>
            <td>{{ pma.data.primma.model.random.Et }}</td>
            <td>{{ pma.data.primma.model.random.Nt }}</td>
            <td>{{ pma.data.primma.model.random.Ec }}</td>
            <td>{{ pma.data.primma.model.random.Nc }}</td>
            <td colspan="2">
                &nbsp;
            </td>
            <td>
                {{ pma.data.primma.model.random.bt_TE }}
                (
                    {{ pma.data.primma.model.random.bt_lower }};
                    {{ pma.data.primma.model.random.bt_upper }}
                )
            </td>
            <td>100%</td>
        </tr>
        <tr>
            <td colspan="2">
                <b>
                  Fixed Effect Model:
                </b>
            </td>
            <td>{{ pma.data.primma.model.fixed.Et }}</td>
            <td>{{ pma.data.primma.model.fixed.Nt }}</td>
            <td>{{ pma.data.primma.model.fixed.Ec }}</td>
            <td>{{ pma.data.primma.model.fixed.Nc }}</td>
            <td colspan="2">
                &nbsp;
            </td>
            <td>
                {{ pma.data.primma.model.fixed.bt_TE }}
                (
                    {{ pma.data.primma.model.fixed.bt_lower }};
                    {{ pma.data.primma.model.fixed.bt_upper }}
                )
            </td>
            <td>100%</td>
        </tr>

        <!-- Heterogeneity -->
        <tr>
            <td colspan="5">
                Heterogeneity: 
                <i>I<sup>2</sup></i> = {{ pma.data.primma.heterogeneity.i2 }},
                <i>τ<sup>2</sup></i> = {{ pma.data.primma.heterogeneity.tau2 }},
                <i>p</i> = {{ pma.data.primma.heterogeneity.p }}
            </td>
            <td colspan="5"></td>
        </tr>
    </table>
    </div>
  </div>

  <div class="box w-100">
    <div class="box-header">
      <i class="fas fa-balance-scale"></i>
      CoE - <b><i>Risk of Bias</i></b>
    </div>
    <div v-if="pma != null" 
      class="box-body d-flex flex-direction-row">
      <div class="text-exp">
        <p class="fact">
          All evaluated = <b>{{ pma.data.coe.info.risk_of_bias.n_rob_na == 0 }}</b>
          (N_NA = {{ pma.data.coe.info.risk_of_bias.n_rob_na }})
          <br>
          All Low risk = <b>{{ pma.data.coe.info.risk_of_bias.is_all_low }}</b> <br>
          All high risk / some concerns = <b>{{ pma.data.coe.info.risk_of_bias.is_all_high }}</b> <br>
          Subgroup Analysis (Low vs. High/Some) P-value = <b>{{ pma.data.coe.info.risk_of_bias.subg_pval }}</b> <br>
          Percentage of High-risk studies = <b>{{ pma.data.coe.info.risk_of_bias.per_high_stus }}</b>
        </p>
    
        <p class="result">
          Result = {{ pma.data.coe.risk_of_bias }}
          ({{ coe_helper.val_to_label(pma.data.coe.risk_of_bias, 'risk_of_bias') }})
          <br>
          <span class="reason">
            {{ pma.data.coe.info.risk_of_bias.reason.msg }}
          </span>
        </p>
      </div>
      <div class="visual-exp">
        <div id="mermaid_rob" 
          class="mermaid" 
          v-html="mermaid_chart_rob">
        </div>
      </div>
    </div>
  </div>

  <div class="box">
    <div class="box-header">
      <i class="fas fa-balance-scale"></i>
      CoE - <b><i>Imprecision</i></b>
    </div>
    <div v-if="pma != null" 
      class="box-body d-flex flex-direction-row">
      <div class="text-exp">
        <p class="fact">
            T = {{ pma.data.coe.info.imprecision.t }} (
                Is T user-provided? = <b>{{ pma.data.coe.info.imprecision.is_t_user_provided }}</b> ) <br>
            CI of RD: <b>({{ pma.data.coe.info.imprecision.ci_of_rd[0].toFixed(4) }}; 
                        {{ pma.data.coe.info.imprecision.ci_of_rd[1].toFixed(4) }})</b> <br>
            Does CI of RD include T? <b>{{ pma.data.coe.info.imprecision.is_t_included_in_ci_of_rd }}</b> <br>
            Relative Effect =  <b>{{ pma.data.coe.info.imprecision.sm }}</b> <br>
            Is relative effect large? <b>{{ pma.data.coe.info.imprecision.is_relative_effect_large }}</b> <br>
            MA Size = <b>{{ pma.data.coe.info.imprecision.ma_size }}</b> <br>
            Et = <b>{{ pma.data.coe.info.imprecision.ttEt }}</b> <br>
            Nt = <b>{{ pma.data.coe.info.imprecision.ttNt }}</b> <br>
            Ec = <b>{{ pma.data.coe.info.imprecision.ttEc }}</b> <br>
            Nc = <b>{{ pma.data.coe.info.imprecision.ttNc }}</b> <br>
            OIS = <b>{{ pma.data.coe.info.imprecision.ois }}</b> 
            (50% OIS= <b>{{ pma.data.coe.info.imprecision.ois * 0.5 }}</b> ) <br>
        </p>


        <p class="result">
            Result = {{ pma.data.coe.imprecision }}
            ({{ coe_helper.val_to_label(pma.data.coe.imprecision, 'imprecision') }})
            <br>
            <span class="reason">
                {{ pma.data.coe.info.imprecision.reason.msg }}
            </span>
        </p>
      </div>
      <div class="visual-exp">
        <div id="mermaid_imp" 
            class="mermaid"
            v-html="mermaid_chart_imp">
        </div>
      </div>
    </div>
  </div>

  <div class="box">
    <div class="box-header">
      <i class="fas fa-balance-scale"></i>
      CoE - <b><i>Inconsistency</i></b>
    </div>
    <div v-if="pma != null" class="box-body d-flex flex-direction-row">
      <div class="text-exp">
        <p class="fact">
          I<sup>2</sup> = <b>{{ pma.data.coe.info.inconsistency.i2 }}</b> <br>
          Category of pooled effect size = <b>{{ pma.data.coe.info.inconsistency.pooled_sm_cate }}</b> <br>
          Major category of studies: <b>{{ pma.data.coe.info.inconsistency.major_sm_cate }} {{
            pma.data.coe.info.inconsistency.major_sm_cnt }}</b> <br>
          RR/OR: <b>T</b>rivial (0.9-1.0),
          <b>S</b>mall (0.8-0.9),
          <b>M</b>oderate (0.5-0.8)
          <b>L</b>arge (&lt; 0.5)
          <br>
          Is 75% within the same category of pooled effect size?
          <b>{{ pma.data.coe.info.inconsistency.is_major_in_same_category }}</b>
          <br>
        </p>
    
        <p class="result">
          Result = {{ pma.data.coe.inconsistency }}
          ({{ coe_helper.val_to_label(pma.data.coe.inconsistency, 'inconsistency') }})
          <br>
          <span class="reason">
            {{ pma.data.coe.info.inconsistency.reason.msg }}
          </span>
        </p>
      </div>
      <div class="visual-exp">
        <div id="mermaid_inc" 
          class="mermaid" 
          v-html="mermaid_chart_inc">
        </div>
      </div>
    </div>
  </div>

  <div class="box">
    <div class="box-header">
      <i class="fas fa-balance-scale"></i>
      CoE - <b><i>Publication Bias</i></b>
    </div>
    <div v-if="pma != null" 
      class="box-body d-flex flex-direction-row">
      <div class="text-exp">
        <p class="fact">
          N = <b>{{ pma.data.coe.info.publication_bias.n_studies }}</b> <br>
          Egger's Test p = <b>{{ pma.data.coe.info.publication_bias.egger_test_p_value }}</b> <br>
          Pooled Effect = <b>{{ pma.data.coe.info.publication_bias.pooled_sm }} </b><br>
          Adjusted Effect = <b>{{ pma.data.coe.info.publication_bias.adjusted_sm }}</b> <br>
          Effect Difference = <b>{{ (pma.data.coe.info.publication_bias.difference_sm).toFixed(4) }}</b><br>
        </p>
      
        <p class="result">
          Result = {{ pma.data.coe.publication_bias }}
          ({{ coe_helper.val_to_label(pma.data.coe.publication_bias, 'publication_bias') }})
          <br>
          <span class="reason">
            {{ pma.data.coe.info.publication_bias.reason.msg }}
          </span>
        </p>
      </div>
      <div class="visual-exp">
        <div id="mermaid_pbb" 
          class="mermaid" 
          v-html="mermaid_chart_pbb">
        </div>
      </div>
    </div>
  </div>

  <div class="box">
    <div class="box-header">
      <i class="fas fa-balance-scale"></i>
      CoE - <b><i>Indirectness</i></b>
    </div>
    <div v-if="pma != null" 
      class="box-body d-flex flex-direction-row">
      <div class="text-exp">
        <p class="fact">
            Number of "Very Close" = <b>{{ pma.data.coe.info.indirectness.n_very_close }}</b> <br>
            Percentage of "Very Close" = <b>{{ to_percentage(pma.data.coe.info.indirectness.n_very_close / pma.data.coe.info.indirectness.n_studies) }}</b> <br>
            Number of "Moderately Close" = <b>{{ pma.data.coe.info.indirectness.n_moderately_close }}</b> <br>
            Number of "Not Close" = <b>{{ pma.data.coe.info.indirectness.n_not_close }}</b> <br>
            Number of studies = <b>{{ pma.data.coe.info.indirectness.n_studies }}</b>
        </p>

        <p class="result">
            Result = {{ pma.data.coe.indirectness }}
            ({{ coe_helper.val_to_label(pma.data.coe.indirectness, 'indirectness') }})
            <br>
            <span class="reason">
                {{ pma.data.coe.info.indirectness.reason.msg }}
            </span>
        </p>
      </div>
      <div class="visual-exp">
        <div id="mermaid_ind" 
            class="mermaid"
            v-html="mermaid_chart_ind">
        </div>
      </div>
    </div>
  </div>

</div>
</template>

<style scoped>
.header {
  font-size: 1.5em;
  padding: 0;
  text-align: left;
  font-weight: bold;
}
#input_panel {
  width: 100%;
  padding: 10px;
  height: 50px;

  background-color: #e5f2fa;
  border-right: 1px solid #EAEAEA;

  display: flex;
  flex-direction: column;

  position: absolute;
  top: 0;
  left: 0;
  border-bottom: 1px solid #dfdfdf;
}
.param_panel {
  width: 100%;
  display: flex;
  justify-content: start;
  align-items: center;
}
#result_panel {
  width: 100%;
  height: 100%;
  display: flex;
  flex-direction: column;
  overflow-y: auto;
  overflow-x: hidden;
  padding-top: 70px;
}
.box {
  width: auto;
  padding: 5px;
  margin-bottom: 5px;
  border-bottom: 1px solid #dfdfdf;
}
.col-item {
  width: 400px;
  margin-right: 10px;
}
.w-100 {
  width: 100%;
}
.box-header {
  padding: 5px 0;
}
.box-body {
  width: 100%;
}
.d-flex {
  display: flex;
}
.flex-direction-row {
  flex-direction: row;
}
.ma-table {
  width: 100%;
}

.ma-table tr {
  text-align: left;
  border-bottom: 1px solid #eeeeee;
}

.ma-table td {
  padding: 2px 3px;
  border-bottom: 1px solid #dfdfdf;
}
.ma-table th {
  background-color: #f3f3f3;
  border-bottom: 1px solid #dfdfdf;
}

.text-exp {
  width: 300px;
  padding: 5px;
  border-right: 1px solid #EAEAEA;
}
.reason {
  font-weight: bold;
}
.result {
  padding: 5px 0 0 0;
  font-size: 1.2em;
  border-top: 1px solid #dfdfdf;
}
.visual-exp {
  width: calc(100% - 310px);
}


.paramter-box {
    width: 200px;
    display: flex;
    flex-direction: column;
    align-items: center;
}
.param-item {
    width: 100%;
    display: flex;
    flex-direction: column;
    margin-bottom: 3px;
    justify-content: start;
}
.item-label {
    width: 120px;
    text-align: left;
}
.item-value {
    width: 100%;
}
.item-desc {
    font-size: 0.9em;
}
.item-value select {
    width: 100%;
}
</style>
