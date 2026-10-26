# Maven Fuzzy Factory | E-Commerce Conversion Optimization

**End-to-End E-Commerce Analytics Project Using PostgreSQL, Python, Pandas, and Tableau**

## Project Overview

Maven Fuzzy Factory is an e-commerce analytics project focused on understanding website performance, customer purchasing behavior, and conversion opportunities.

The project analyzes website sessions, pageviews, orders, marketing channels, and product performance to identify factors influencing customer conversions.

The primary objective is to investigate **why website visitors do not complete purchases and which areas of the customer journey offer the greatest opportunities for conversion improvement**.

## Business Problem

An e-commerce business can generate substantial website traffic without converting enough visitors into paying customers.

To improve business performance, it is important to understand:

- Which marketing channels generate valuable traffic?
- Which landing pages convert visitors into customers?
- Where do customers abandon the shopping funnel?
- How does conversion performance differ between desktop and mobile users?
- Are returning visitors more likely to purchase than new visitors?
- Which products contribute most to revenue and profitability?

This project uses data analysis to investigate these questions and identify potential business improvements.

## Tools and Technologies

- **PostgreSQL:** Data exploration, joins, aggregations, CTEs, window functions, and KPI calculations.
- **Python:** Data analysis and exploration.
- **Pandas:** Data manipulation and analytical workflows.
- **Tableau:** Business intelligence and data visualization.
- **Git and GitHub:** Version control and project documentation.

## Dataset Overview

The dataset contains e-commerce activity from March 2012 to March 2015.

| Dataset | Total Records |
|---|---:|
| Website Sessions | 472,871 |
| Website Pageviews | 1,188,124 |
| Orders | 32,313 |

Additional product and order-item data support revenue and profitability analysis.

## Project Objectives

1. Measure overall website conversion performance.
2. Evaluate marketing traffic sources and campaigns.
3. Compare landing-page effectiveness.
4. Identify shopping-funnel abandonment points.
5. Analyze desktop and mobile conversion differences.
6. Compare new and returning visitor behavior.
7. Evaluate landing-page conversion by device type.
8. Examine product revenue and profitability.

## Key Performance Indicators

| KPI | Definition |
|---|---|
| Website Sessions | Total recorded website visits |
| Sessions With Orders | Sessions containing at least one order |
| Session Conversion Rate | Sessions with orders / Total sessions × 100 |
| Landing-Page Conversion Rate | Ordering sessions starting on a landing page / Sessions starting on that page × 100 |
| Funnel Progression Rate | Sessions reaching the next stage / Sessions reaching the current stage × 100 |
| Funnel Drop-Off Rate | 100% − Funnel progression rate |
| Average Order Value | Total revenue / Number of orders |
| Profit Margin | (Revenue − Cost of Goods Sold) / Revenue × 100 |

## Key Analytical Findings

### 1. Overall Website Conversion

- **Total website sessions:** 472,871
- **Total orders:** 32,313
- **Session conversion rate:** 6.83%

Approximately 6.83% of website sessions resulted in a purchase, indicating an opportunity to investigate why most visits do not convert.

### 2. Landing-Page Performance

| Landing Page | Conversion Rate |
|---|---:|
| `/lander-5` | 10.17% |
| `/lander-2` | 7.72% |
| `/lander-4` | 7.54% |
| `/home` | 7.06% |
| `/lander-1` | 4.53% |
| `/lander-3` | 3.39% |

**Finding:** `/lander-5` recorded the highest conversion rate among the analyzed landing pages, while `/lander-3` performed the worst.

This difference suggests that landing-page design, traffic quality, and user experience deserve further investigation.

### 3. Shopping Funnel Analysis

| Funnel Stage | Sessions | Progression From Previous Stage |
|---|---:|---:|
| Product Page | 261,231 | — |
| Cart | 94,953 | 36.35% |
| Shipping | 64,484 | 67.91% |
| Billing | 48,441 | 75.12% |
| Purchase Confirmation | 32,313 | 66.71% |

**Key findings:**

- The largest funnel drop-off occurred between product pages and the cart, at **63.65%**.
- Approximately **32.09%** of sessions reaching the cart did not progress to shipping.
- Approximately **33.29%** of sessions reaching billing did not progress to purchase confirmation.

The product-to-cart transition represents the largest observed opportunity for funnel improvement.

### 4. Marketing Channel Performance

| Traffic Segment | Conversion Rate |
|---|---:|
| Bing Search — Brand | 8.86% |
| Google Search — Brand | 7.53% |
| Unattributed Traffic | 7.34% |
| Bing Search — Nonbrand | 6.95% |
| Google Search — Nonbrand | 6.66% |
| Socialbook — Desktop Targeted | 5.15% |
| Socialbook — Pilot | 1.08% |

**Finding:** Branded search traffic generally converted at higher rates than nonbranded search and the analyzed social campaigns.

This suggests that customer purchase intent may vary significantly across acquisition channels.

### 5. Desktop vs. Mobile Conversion

| Device | Sessions | Sessions With Orders | Conversion Rate |
|---|---:|---:|---:|
| Desktop | 327,027 | 27,805 | 8.50% |
| Mobile | 145,844 | 4,508 | 3.09% |

**Finding:** Desktop sessions converted at approximately 2.75 times the mobile session conversion rate.

The gap suggests that mobile user experience, checkout usability, and traffic composition should be investigated.

### 6. New vs. Returning Visitors

| Visitor Type | Sessions | Sessions With Orders | Conversion Rate |
|---|---:|---:|---:|
| New | 394,318 | 26,164 | 6.64% |
| Returning | 78,553 | 6,149 | 7.83% |

**Finding:** Returning visitors had a higher conversion rate than new visitors.

This indicates that repeat engagement is associated with stronger purchasing behavior in the observed data.

### 7. Landing-Page Conversion by Device

The latest SQL analysis combines landing-page identification with device-level conversion measurement.

For each landing page and device type, the query calculates:

- Total website sessions.
- Sessions containing orders.
- Session conversion rate.

The analysis uses PostgreSQL window functions to identify the first pageview of each session, then joins landing-page data with website sessions and orders.

**Business question:** Which landing pages perform best on desktop and mobile?

This analysis provides a more detailed view of landing-page effectiveness by separating desktop and mobile performance. Device-specific results have not yet been included in the reported findings.

### 8. Product Revenue and Profitability

The product-level analysis identifies revenue contribution and profit margins across the product portfolio.

| Product | Revenue (USD) |
|---|---:|
| Original Mr. Fuzzy | $1,211,057.74 |
| Forever Love Bear | $347,702.04 |
| Birthday Sugar Panda | $229,260.15 |
| Hudson River Mini Bear | $150,489.82 |

**Profitability findings:**

- Birthday Sugar Panda: 68.49% profit margin.
- Hudson River Mini Bear: 68.36% profit margin.
- Forever Love Bear: 62.51% profit margin.
- Original Mr. Fuzzy: 61.01% profit margin.

Original Mr. Fuzzy generated the highest revenue among the listed products, while Birthday Sugar Panda achieved the highest profit margin.

## Business Recommendations

Based on the analytical findings, the following areas warrant investigation:

1. **Improve product-to-cart progression:** Investigate product-page clarity, pricing presentation, and add-to-cart usability.
2. **Evaluate mobile conversion barriers:** Examine mobile navigation, page performance, and checkout usability.
3. **Review landing-page performance:** Investigate why high-converting pages outperform lower-converting pages, accounting for traffic differences.
4. **Optimize marketing acquisition:** Compare branded, nonbranded, and social traffic using conversion performance alongside acquisition costs.
5. **Encourage returning customer engagement:** Explore retention and remarketing opportunities based on the higher observed conversion rate of returning visitors.
6. **Balance revenue and profitability:** Consider both sales volume and profit margin when evaluating product performance.

## Analytical Approach

The PostgreSQL analysis uses:

- SQL joins to combine sessions, pageviews, orders, and product information.
- Common Table Expressions (CTEs) to organize multistage analytical queries.
- Window functions to identify session landing pages.
- Conditional aggregation to calculate sessions containing orders.
- Funnel-stage calculations to measure customer progression.
- Grouped aggregations to compare devices, campaigns, and visitor segments.
- Revenue, cost, and margin calculations to evaluate product performance.

## Project Conclusion

The Maven Fuzzy Factory analysis identifies several important patterns in e-commerce conversion performance.

The largest observed shopping-funnel loss occurs before visitors add products to their carts. Desktop users convert substantially more frequently than mobile users, returning visitors demonstrate stronger conversion behavior than new visitors, and landing-page performance varies considerably.

Marketing channel differences and product profitability further demonstrate the importance of evaluating business performance from multiple perspectives.

Together, these findings provide a data-driven foundation for prioritizing conversion optimization opportunities, evaluating customer behavior, and supporting e-commerce business decisions.
