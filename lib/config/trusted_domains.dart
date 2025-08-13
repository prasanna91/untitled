const List<Map<String, String>> trustedDomains = [
  // Identity Providers (SSO / Social Login)
  {"name": "Google", "domain": "accounts.google.com"},
  {"name": "Google", "domain": "accounts.youtube.com"},
  {"name": "Google", "domain": "gstatic.com"},
  {"name": "Google", "domain": "googleusercontent.com"},
  {"name": "Google", "domain": "google.com"},
  {"name": "Apple", "domain": "appleid.apple.com"},
  {"name": "Facebook", "domain": "facebook.com"},
  {"name": "Amazon", "domain": "amazon.com"},
  {"name": "Microsoft", "domain": "login.microsoftonline.com"},
  {"name": "Yahoo", "domain": "login.yahoo.com"},
  {"name": "Twitter (X)", "domain": "twitter.com"},
  {"name": "LinkedIn", "domain": "linkedin.com"},
  {"name": "Shopify", "domain": "shopify.com"},
  {"name": "Shopify", "domain": "*.myshopify.com"},
  {"name": "Shopify", "domain": "cdn.shopify.com"},
  {"name": "Shopify", "domain": "assets.shopifycdn.com"},
  {"name": "Shopify", "domain": "shops.shopify.com"},
  {"name": "Shopify", "domain": "apps.shopify.com"},
  {"name": "Shopify", "domain": "checkout.shopify.com"},

  // WooCommerce / WordPress
  {"name": "WooCommerce", "domain": "woocommerce.com"},
  {"name": "WordPress", "domain": "wordpress.com"},
  {"name": "WordPress", "domain": "*.wordpress.com"},
  {"name": "WordPress", "domain": "wp-content.com"},
  {"name": "WordPress", "domain": "wp-includes.com"},

  // Wix
  {"name": "Wix", "domain": "wix.com"},
  {"name": "Wix", "domain": "*.wixsite.com"},
  {"name": "Wix", "domain": "wixstatic.com"},
  {"name": "Wix", "domain": "wixapps.com"},
  {"name": "Wix", "domain": "wixapps.net"},

  // Squarespace
  {"name": "Squarespace", "domain": "squarespace.com"},
  {"name": "Squarespace", "domain": "*.squarespace.com"},
  {"name": "Squarespace", "domain": "squarespace-cdn.com"},
  {"name": "Squarespace", "domain": "squarespace.net"},

  // BigCommerce
  {"name": "BigCommerce", "domain": "bigcommerce.com"},
  {"name": "BigCommerce", "domain": "*.mybigcommerce.com"},
  {"name": "BigCommerce", "domain": "cdn.bigcommerce.com"},
  {"name": "BigCommerce", "domain": "store.bigcommerce.com"},

  // Magento
  {"name": "Magento", "domain": "magento.com"},
  {"name": "Magento", "domain": "magentocommerce.com"},
  {"name": "Magento", "domain": "magento.cloud"},

  // PrestaShop
  {"name": "PrestaShop", "domain": "prestashop.com"},
  {"name": "PrestaShop", "domain": "prestashop.cloud"},

  // OpenCart
  {"name": "OpenCart", "domain": "opencart.com"},

  // Volusion
  {"name": "Volusion", "domain": "volusion.com"},
  {"name": "Volusion", "domain": "*.volusion.com"},

  // 3dcart
  {"name": "3dcart", "domain": "3dcart.com"},
  {"name": "3dcart", "domain": "*.3dcartstores.com"},

  // Weebly
  {"name": "Weebly", "domain": "weebly.com"},
  {"name": "Weebly", "domain": "*.weebly.com"},
  {"name": "Weebly", "domain": "weeblycdn.com"},

  // GoDaddy Website Builder
  {"name": "GoDaddy", "domain": "godaddy.com"},
  {"name": "GoDaddy", "domain": "*.godaddysites.com"},
  {"name": "GoDaddy", "domain": "godaddysites.com"},

  // Hostinger Website Builder
  {"name": "Hostinger", "domain": "hostinger.com"},
  {"name": "Hostinger", "domain": "*.hostinger.com"},

  // Jimdo
  {"name": "Jimdo", "domain": "jimdo.com"},
  {"name": "Jimdo", "domain": "*.jimdofree.com"},
  {"name": "Jimdo", "domain": "*.jimdosite.com"},

  // Webflow
  {"name": "Webflow", "domain": "webflow.com"},
  {"name": "Webflow", "domain": "*.webflow.io"},
  {"name": "Webflow", "domain": "webflow.io"},

  // Bubble
  {"name": "Bubble", "domain": "bubble.io"},
  {"name": "Bubble", "domain": "*.bubbleapps.io"},

  // Carrd
  {"name": "Carrd", "domain": "carrd.co"},
  {"name": "Carrd", "domain": "*.carrd.co"},

  // Strikingly
  {"name": "Strikingly", "domain": "strikingly.com"},
  {"name": "Strikingly", "domain": "*.strikingly.com"},

  // Tilda
  {"name": "Tilda", "domain": "tilda.cc"},
  {"name": "Tilda", "domain": "*.tilda.ws"},
  {"name": "Tilda", "domain": "tilda.ws"},

  // Framer
  {"name": "Framer", "domain": "framer.com"},
  {"name": "Framer", "domain": "*.framer.app"},
  {"name": "Framer", "domain": "framer.app"},

  // Notion
  {"name": "Notion", "domain": "notion.so"},
  {"name": "Notion", "domain": "*.notion.site"},

  // Airtable
  {"name": "Airtable", "domain": "airtable.com"},
  {"name": "Airtable", "domain": "*.airtable.com"},

  // Zapier
  {"name": "Zapier", "domain": "zapier.com"},
  {"name": "Zapier", "domain": "*.zapier.com"},

  // Integromat (Make)
  {"name": "Make", "domain": "make.com"},
  {"name": "Make", "domain": "*.make.com"},

  // Shipping & Logistics
  {"name": "ShipRocket", "domain": "shiprocket.in"},
  {"name": "ShipRocket", "domain": "uc.shiprocket.in"},

  // Analytics & Tracking
  {"name": "Google Analytics", "domain": "merchant-center-analytics.goog"},
  {"name": "Google Analytics", "domain": "*.goog"},
  {"name": "AdRoll", "domain": "adroll.com"},
  {"name": "AdRoll", "domain": "d.adroll.com"},
  {"name": "LiveRamp", "domain": "rlcdn.com"},
  {"name": "LiveRamp", "domain": "idsync.rlcdn.com"},

  // E-commerce Tools
  {"name": "Kiwi Sizing", "domain": "kiwisizing.com"},
  {"name": "Kiwi Sizing", "domain": "app.kiwisizing.com"},

  // Shopify Specific
  {"name": "Shopify Monorail", "domain": "*.well-known"},
  {"name": "Shopify CDN", "domain": "cdn.shopify.com"},
  {"name": "Shopify Files", "domain": "files.shopify.com"},

  // Custom domains
  {"name": "Shopify", "domain": "apps.hiko.link"},
  {"name": "login", "domain": "hiko.link"},
  {"name": "Twinklub", "domain": "twinklub.com"},

  // Major Payment Gateways
  {"name": "Stripe", "domain": "stripe.com"},
  {"name": "PayPal", "domain": "paypal.com"},
  {"name": "Square", "domain": "squareup.com"},
  {"name": "Adyen", "domain": "adyen.com"},
  {"name": "Authorize.Net", "domain": "authorize.net"},
  {"name": "2Checkout (Verifone)", "domain": "2checkout.com"},
  {"name": "Braintree", "domain": "braintreepayments.com"},
  {"name": "Amazon Pay", "domain": "pay.amazon.com"},
  {"name": "Apple Pay", "domain": "apple.com"},
  {"name": "Google Pay", "domain": "pay.google.com"},
  {"name": "Worldpay", "domain": "worldpay.com"},
  {"name": "Klarna", "domain": "klarna.com"},
  {"name": "Checkout.com", "domain": "checkout.com"},
  {"name": "BlueSnap", "domain": "bluesnap.com"},
  {"name": "Mollie", "domain": "mollie.com"},

  // India-Based Payment Platforms
  {"name": "Razorpay", "domain": "razorpay.com"},
  {"name": "Paytm", "domain": "paytm.com"},
  {"name": "PhonePe", "domain": "phonepe.com"},
  {"name": "CCAvenue", "domain": "ccavenue.com"},
  {"name": "Instamojo", "domain": "instamojo.com"},
  {"name": "JusPay", "domain": "juspay.in"},
  {"name": "Cashfree", "domain": "cashfree.com"},
  {"name": "BillDesk", "domain": "billdesk.com"},
  {"name": "PayU India", "domain": "payu.in"},

  // Global / Regional Gateways
  {"name": "Mercado Pago", "domain": "mercadopago.com"},
  {"name": "iDEAL (Netherlands)", "domain": "ideal.nl"},
  {"name": "Payoneer", "domain": "payoneer.com"},
  {"name": "Alipay", "domain": "intl.alipay.com"},
  {"name": "WeChat Pay", "domain": "pay.weixin.qq.com"}
];

// const List<Map<String, String>> trustedDomains = [
//   { "name": "Stripe", "domain": "stripe.com" },
//   { "name": "PayPal", "domain": "paypal.com" },
//   { "name": "Square", "domain": "squareup.com" },
//   { "name": "Adyen", "domain": "adyen.com" },
//   { "name": "Authorize.Net", "domain": "authorize.net" },
//   { "name": "2Checkout (Verifone)", "domain": "2checkout.com" },
//   { "name": "Braintree", "domain": "braintreepayments.com" },
//   { "name": "Amazon Pay", "domain": "pay.amazon.com" },
//   { "name": "Apple Pay", "domain": "apple.com" },
//   { "name": "Google Pay", "domain": "pay.google.com" },
//   { "name": "Worldpay", "domain": "worldpay.com" },
//   { "name": "Klarna", "domain": "klarna.com" },
//   { "name": "Checkout.com", "domain": "checkout.com" },
//   { "name": "BlueSnap", "domain": "bluesnap.com" },
//   { "name": "Mollie", "domain": "mollie.com" },
//   { "name": "Razorpay", "domain": "razorpay.com" },
//   { "name": "Paytm", "domain": "paytm.com" },
//   { "name": "PhonePe", "domain": "phonepe.com" },
//   { "name": "CCAvenue", "domain": "ccavenue.com" },
//   { "name": "Instamojo", "domain": "instamojo.com" },
//   { "name": "JusPay", "domain": "juspay.in" },
//   { "name": "Cashfree", "domain": "cashfree.com" },
//   { "name": "BillDesk", "domain": "billdesk.com" },
//   { "name": "PayU India", "domain": "payu.in" },
//   { "name": "Mercado Pago", "domain": "mercadopago.com" },
//   { "name": "iDEAL", "domain": "ideal.nl" },
//   { "name": "Payoneer", "domain": "payoneer.com" },
//   { "name": "Alipay", "domain": "intl.alipay.com" },
//   { "name": "WeChat Pay", "domain": "pay.weixin.qq.com" }
// ];
bool isTrustedPaymentDomain(String url) {
  return trustedDomains.any((gateway) => url.contains(gateway['domain']!));
}
