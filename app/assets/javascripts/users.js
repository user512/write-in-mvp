// # Place all the behaviors and hooks related to the matching controller here.
// # All this logic will automatically be available in application.js.

$(function() {
    var availableTags = [
      "Alameda, CA",
      "Contra Costa, CA",
      "Oakland, CA",
      "San Jose, CA",
      "Del Norte, CA",
      "Lake, CA",
      "Marin, CA",
      "Napa, CA",
      "Mendocino, CA",
      "San Mateo, CA",
      "Solano, CA",
      "Sonoma, CA"
    ];
    $( "#setDistrict" ).autocomplete({
      source: availableTags
    });
  });