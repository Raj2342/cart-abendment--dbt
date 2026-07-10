## 🎯 The Business Problem: The $7 Million Bleed

Imagine a high-growth e-commerce startup generating $10 million in annual revenue. A top-level analytics audit reveals a critical bottleneck: a **70% cart abandonment rate**. Users are essentially leaving $7 million worth of products in their digital carts and walking away.

However, the high abandonment rate was only a symptom. The root cause of the financial drain was the company's **"dumb discount system."** In a desperate attempt to recover abandoned carts, the platform was automatically triggering a 10% discount pop-up and sending 24-hour reminder emails to *every single user*. 

This spray-and-pray approach resulted in a massive, two-fold financial bleed:
* **Margin Erosion (Setting Profit on Fire):** The system was unintentionally giving 10% discounts to "Safe Buyers"—users who had high intent and were going to check out at full price anyway. 
* **Wasted Ad Spend (Plummeting ROAS):** The marketing team was burning their paid retargeting budget on "Window Shoppers"—users who used the cart as a wishlist with absolutely zero purchase intent.

**The Objective:**
The company possessed the raw clickstream data, but lacked a rule-based diagnostic engine to classify user intent. They required an automated framework to determine exactly *who* should receive a discount to recover a sale, and more importantly, *who should be blocked* from discounts to protect profit margins.

---

## ⚙️ Core Analytical Execution & Intent Classification

To translate this business problem into actionable data logic, I engineered a behavioral classification model using session logs and cart events, breaking the pipeline into four strategic pillars:

1. **Establishing the Baseline (Total Revenue at Risk):** Before applying algorithms, I quantified the exact size of the problem. By filtering session logs where `event_type = 'cart'` without a subsequent `purchase` event, I aggregated the total pipeline value at risk. This established the primary financial KPI—you cannot fix a problem without proving its scale first.
2. **Plugging the Margin Bleed (The "Safe Buyers"):** Analyzed session velocity and category focus. Users who navigated directly to specific categories and added to their cart rapidly demonstrated high purchase intent. The engine tags these users to **block discount triggers**, ensuring they convert at full price and immediately saving profit margins.
3. **Surgical Rescue Targeting (The "Hesitant Buyers"):** Engineered a 'Browse-to-Cart Ratio' metric. Users who viewed 15+ items over an extended session before adding to the cart were flagged as price-shopping or hesitant. The system signals the marketing engine to trigger the 10% recovery pop-up *only* for this highly receptive segment.
4. **Filtering the Noise (The "Window Shoppers"):** Identified behavioral anomalies, such as users with absurdly high cart values (e.g., $15,000) containing 40+ disparate items. These profiles are tagged as 'Stagnant' and systematically excluded from both discount triggers and paid ad retargeting campaigns, directly decreasing Customer Acquisition Cost (CAC) and improving overall return on ad spend.
