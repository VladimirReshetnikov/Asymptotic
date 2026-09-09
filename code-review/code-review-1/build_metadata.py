from pathlib import Path
import json,csv,re,platform
root=Path(__file__).resolve().parent
commit='07a9781212beb2eeb9ff16aa625b50ac27974078'
base=f'https://github.com/VladimirReshetnikov/Asymptotic/blob/{commit}/'
repo_sources=[
 ('revision','Pinned revision and commit metadata',f'https://github.com/VladimirReshetnikov/Asymptotic/commit/{commit}'),
 ('tree','Pinned repository tree',f'https://github.com/VladimirReshetnikov/Asymptotic/tree/{commit}'),
 ('readme','Repository README','README.md'),
 ('paclet','Paclet metadata','AsymptoticInverse/PacletInfo.wl'),
 ('core','Canonical main kernel','AsymptoticInverse/Kernel/AsymptoticInverse.wl'),
 ('operations','Series operations','AsymptoticInverse/Kernel/SeriesOperations.wl'),
 ('arithmetic','Arithmetic and held normalization','AsymptoticInverse/Kernel/SeriesArithmetic.wl'),
 ('incremental','Incremental inverse states and Newton refinement','AsymptoticInverse/Kernel/IncrementalInverse.wl'),
 ('certificates','Exact inverse certificates','AsymptoticInverse/Kernel/InverseCertificates.wl'),
 ('inverseexpressions','Applied inverse expressions and public wrappers','AsymptoticInverse/Kernel/InverseFunctionExpressions.wl'),
 ('sourcecharts','Source coordinate transformations','AsymptoticInverse/Kernel/SourceCoordinates.wl'),
 ('gamma','Gamma and Barnes inverse construction','AsymptoticInverse/Kernel/GammaInverse.wl'),
 ('native','Native special-function expansion adapter','AsymptoticInverse/Kernel/NativeSpecialFunctions.wl'),
 ('guide','Current user guide','AsymptoticInverse/Documentation/UserGuide.md'),
 ('validation','Validation record','validation/README.md'),
 ('runner','Focused native test runner','validation/FocusedTests.wl'),
 ('workflow','Standalone freshness workflow','.github/workflows/standalone.yml'),
 ('development','Development and standalone provenance notes','docs/development/README.md'),
 ('repoarticle','Mathematical article, top-level LaTeX source','article/asymptotic-inverse.tex'),
 ('license','Repository license text','LICENSE')]
web_sources=[
 ('wl-series','Wolfram Research','Series','https://reference.wolfram.com/language/ref/Series.html'),
 ('wl-seriesdata','Wolfram Research','SeriesData','https://reference.wolfram.com/language/ref/SeriesData.html'),
 ('wl-inverse','Wolfram Research','InverseSeries','https://reference.wolfram.com/language/ref/InverseSeries.html'),
 ('wl-compose','Wolfram Research','ComposeSeries','https://reference.wolfram.com/language/ref/ComposeSeries.html'),
 ('wl-asymptotic','Wolfram Research','Asymptotic','https://reference.wolfram.com/language/ref/Asymptotic.html'),
 ('wl-solve','Wolfram Research','AsymptoticSolve','https://reference.wolfram.com/language/ref/AsymptoticSolve.html'),
 ('wl-discrete','Wolfram Research','DiscreteAsymptotic','https://reference.wolfram.com/language/ref/DiscreteAsymptotic.html'),
 ('wl-less','Wolfram Research','AsymptoticLess','https://reference.wolfram.com/language/ref/AsymptoticLess.html'),
 ('wl-o','Wolfram Research','O','https://reference.wolfram.com/language/ref/O.html'),
 ('wl-assuming','Wolfram Research','Assuming','https://reference.wolfram.com/language/ref/Assuming.html'),
 ('wl-simplify','Wolfram Research','Simplify','https://reference.wolfram.com/language/ref/Simplify.html'),
 ('wl-assumptions','Wolfram Research','Assumptions','https://reference.wolfram.com/language/ref/Assumptions.html'),
 ('dlmf-asymptotic','NIST Digital Library of Mathematical Functions','Section 2.1: Definitions and elementary properties of asymptotic approximations','https://dlmf.nist.gov/2.1'),
 ('dlmf-gamma','NIST Digital Library of Mathematical Functions','Section 5.11: Gamma asymptotic expansions','https://dlmf.nist.gov/5.11'),
 ('dlmf-barnes','NIST Digital Library of Mathematical Functions','Section 5.17: Barnes G-function','https://dlmf.nist.gov/5.17'),
 ('spdx','SPDX License List','MIT No Attribution (MIT-0)','https://spdx.org/licenses/MIT-0.html')]
refs=[]
tex=['\\clearpage','\\addcontentsline{toc}{section}{Sources and references}',
 '\\begin{thebibliography}{99}',
 '\\footnotesize']
for key,title,path in repo_sources:
    url=path if path.startswith('http') else base+path
    refs.append(dict(id=key,author='Asymptotic Contributors / Vladimir Reshetnikov',title=title,url=url,type='pinned repository source',accessed='2026-09-09'))
    tex.append(f'\\bibitem{{{key}}} Asymptotic Contributors / V.~Reshetnikov. \\emph{{{title}}}. Revision \\texttt{{07a9781}}, inspected September 9, 2026. \\url{{{url}}}')
for key,author,title,url in web_sources:
    refs.append(dict(id=key,author=author,title=title,url=url,type='official primary reference',accessed='2026-09-09'))
    tex.append(f'\\bibitem{{{key}}} {author}. \\emph{{{title}}}. Official reference, accessed September 9, 2026. \\url{{{url}}}')
tex.append('\\end{thebibliography}')
(root/'article/sources.tex').write_text('\n\n'.join(tex)+'\n')
(root/'evidence/references.json').write_text(json.dumps(refs,indent=2)+'\n')
findings=[
 ('A01','High','Source deduction','Nested observable power bypasses real-branch guard','core; operations','Centralize unknown-sign noninteger power rejection','Prototype supplied; native tests not run'),
 ('A02','High','Source deduction + independent integer calculation','Eager dense SeriesData export has no allocation cap','core','Preflight allocation and make optional export lazy','Interim fixed-cap prototype supplied; native tests not run'),
 ('A03','Medium','Disclosed limitation + independent counterexample','Native export loses explicit logarithmic remainder information','core; guide','Strict conversion or explicit loss report and sidecar','Conservative strict-export prototype supplied; native tests not run'),
 ('A04','High','Source deduction + official Wolfram semantics','Ambient assumptions used without durable provenance','core; inverseexpressions; wl-simplify','Capture effective assumptions and isolate internal evaluation','Design and prospective native tests supplied; no patch'),
 ('A05','High release priority','Repository report + workflow inspection','Current focused validation is not full-suite release coverage','validation; workflow; runner','Add full native release gate','Prospective runner supplied'),
 ('A06','Medium','Source-level design analysis','Fragmented resource accounting and hard-coded limits','core; incremental; native; arithmetic','Shared multidimensional budgets and diagnostic failures','Design recommendation'),
 ('A07','Medium','Documented design complexity','Heterogeneous cutoff and term-goal semantics','guide','Normalize requests and expose their resolved meaning','Design recommendation'),
 ('A08','Medium','Documented compatibility change','Result-head rename affects saved objects and patterns','guide; revision','Schema versioning and explicit migration policy','Design recommendation'),
 ('A09','Low/Medium','Source-confirmed API inconsistency','Automatic certificate interval default is rejected','certificates','Required-option diagnostic or verified automatic bracketing','Design recommendation'),
 ('A10','Medium usability','Metadata inspection','No documentation extension registered in paclet metadata','paclet; guide','Documentation-center pages and executable examples','Design recommendation'),
 ('A11','Medium usability','Documented behavior','Numeric application substitutes finite expression without certification','core; guide','Separate checked evaluator from lightweight substitution','Design recommendation'),
 ('A12','Medium','Documented limitation','Shared head does not imply closure between scales','guide; arithmetic; sourcecharts','Capabilities and shared operation contracts','Design recommendation'),
 ('A13','Investigate','Performance hypothesis','Retained provenance and caches may inflate object size','incremental; inverseexpressions; arithmetic','Profile storage and allow contract-preserving cache compaction','No quantitative performance claim'),
 ('A14','Low/Medium','Documentation + literal metadata mismatch','Mutable quickstart and MIT versus MIT-0 metadata','development; guide; license; paclet; spdx','Pinned releases and consistent license metadata','Release recommendation')]
with (root/'evidence/findings.csv').open('w',newline='') as f:
    w=csv.writer(f);w.writerow(['id','priority','evidence','finding','sources','recommendation','artifact_status']);w.writerows(findings)
coverage=[
 ('AsymptoticInverse/Kernel/AsymptoticInverse.wl','successive ranges across main module; targeted re-reads','central algorithms and A01-A04','ea9eaf4a11130e922ac4fb3faae37fd8e8d29643'),
 ('AsymptoticInverse/Kernel/SeriesOperations.wl','1-320 with overlaps','observable paths and branches',''),
 ('AsymptoticInverse/Kernel/SeriesArithmetic.wl','1-290','normalization and arithmetic',''),
 ('AsymptoticInverse/Kernel/InverseFunctionExpressions.wl','1-130 and 160-end','public wrappers and provenance','200f46ee2994e5b366a1bc169daa58d27861bcdc'),
 ('AsymptoticInverse/Kernel/InverseCertificates.wl','full file through successive windows','interval arithmetic and scope','c447755ab58f02aa8a80fa374329e00d6ff9641e'),
 ('AsymptoticInverse/Kernel/IncrementalInverse.wl','1-155','states caches Newton','11e74e13a35d73bb659e3a827b755c14c8fe9b37'),
 ('AsymptoticInverse/Kernel/SourceCoordinates.wl','1-140','coordinate reconstruction',''),
 ('AsymptoticInverse/Kernel/GammaInverse.wl','1-150','special inverse coefficients and cores','e46c1046f8d9af7a67f4a132c0b3cb6767ca2aea'),
 ('AsymptoticInverse/Kernel/NativeSpecialFunctions.wl','1-150 and 250-end','native adapters and error trees','86ade501d64b0ec9a6cc42a4d9e37bbd580d1485'),
 ('AsymptoticInverse/Documentation/UserGuide.md','1-300','documented interfaces and conventions',''),
 ('AsymptoticInverse/PacletInfo.wl','full file','version license extensions','f41b43c96baf759f7f45256890cb73c097fe977a'),
 ('README.md','connector read','repository overview',''),
 ('validation/README.md','1-150','reported validation and timings',''),
 ('validation/FocusedTests.wl','full file','native runner design','95051a84a824f63754cb63b9b89efdea5d905fce'),
 ('.github/workflows/standalone.yml','full file','CI scope','2ec5fd70e9a297009ec8ddbf7e47545b929f0987'),
 ('docs/development/README.md','full returned text','distribution provenance','af48e55e87503e000ebdd9ebd4cd3c09c43ed60d'),
 ('article/asymptotic-inverse.tex','top-level source; not all included sections','mathematical article scope','96c659e42efa6a180c9b7216e5eff31d6001de79'),
 ('LICENSE','full file','MIT No Attribution text','7d2b7fa09617f2024f157a40a318f4b12586644b')]
with (root/'evidence/source_coverage.csv').open('w',newline='') as f:
    w=csv.writer(f);w.writerow(['repository_path','read_coverage','purpose','git_blob_sha_when_recorded','url'])
    for row in coverage:w.writerow([*row,base+row[0]])
manifest={
 'repository':'https://github.com/VladimirReshetnikov/Asymptotic',
 'commit':commit,'package_version':'1.8.0','commit_timestamp_utc':'2026-09-09T19:01:30Z','review_date':'2026-09-09',
 'declared_wolfram_requirement':'15.0+','native_wolfram_executed':False,
 'native_runtime_limitation':'Connected evaluator failed even on version query; no local Wolfram kernel available.',
 'source_access':'GitHub connector, immutable file/range reads; no local repository checkout assembled.',
 'independent_mathematical_checks':{'passed':42,'failed':0,'file':'mathematical_checks.json','not_package_execution':True},
 'patch_planner_checks':{'passed':6,'failed':0,'scope':'synthetic fixtures only; not applied to real checkout or executed in Wolfram'},
 'native_regressions':{'count':15,'executed':False},'native_benchmarks':{'executed':False},
 'repository_reported_native_validation':{'passed':305,'failed':0,'selected_suites':18,'full_suite_run':False,'independently_replicated':False},
 'findings_count':14,'patch_scope':['A01 conservative guard','A02 interim fixed allocation cap','A03 strict export policy'],
 'not_patched':['A04 ambient assumption provenance','lazy export','unified resource policy'],
 'license_metadata_discrepancy':{'PacletInfo':'MIT','LICENSE':'MIT No Attribution (MIT-0)'},
 'coverage_limit':'No claim of exhaustive line-by-line audit of every module or proof; see source_coverage.csv.'}
(root/'evidence/review_manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
# Validate that every article citation and source input exists.
alltex='\n'.join(p.read_text() for p in (root/'article').rglob('*.tex'))
keys={r['id'] for r in refs}
cited={key for s in re.findall(r'\\cite\{([^}]+)\}',alltex) for key in s.split(',')}
assert not cited-keys,cited-keys
print('References:',len(refs),'Cited:',len(cited),'Findings:',len(findings),'Coverage records:',len(coverage))
print('Approximate LaTeX-source word count:',len(alltex.split()))
