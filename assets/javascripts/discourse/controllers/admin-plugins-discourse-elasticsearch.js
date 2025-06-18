import Controller from "@ember/controller";
import { action } from "@ember/object";
import { tracked } from "@glimmer/tracking";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";

export default class AdminPluginsDiscourseElasticsearchController extends Controller {
  @tracked reindexComplete = false;
  @tracked reindexError = null;

  @action
  reindexPosts() {
    this.reindexComplete = false;
    this.reindexError = null;

    ajax("/discourse-elasticsearch/admin/reindex", {
      type: "POST",
    })
      .then((result) => {
        this.reindexComplete = true;
        if (result.message) {
          console.log("Reindex result:", result.message);
        }
      })
      .catch((error) => {
        const errorMessage = error.jqXHR?.responseJSON?.errors?.[0] || 
                           error.responseJSON?.errors?.[0] || 
                           error.message || 
                           "Unknown error occurred";
        this.reindexError = errorMessage;
        popupAjaxError(error);
      });
  }
}