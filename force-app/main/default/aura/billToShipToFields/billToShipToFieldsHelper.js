({
    isVatNumberCountryCode: function (countryCode) {
        return [
            "AT", "BE", "BG", "CY", "CZ", "DE", "DK", "EE", "EL", "ES",
            "FI", "FR", "GB", "HR", "HU", "IE", "IT", "LT", "LU", "LV",
            "MT", "NL", "PL", "PT", "RO", "SE", "SI", "SK", "CH", "NO",
            "IS", "LI"
        ].includes(countryCode);
    }
})