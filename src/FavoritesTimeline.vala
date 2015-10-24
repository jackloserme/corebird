/*  This file is part of corebird, a Gtk+ linux Twitter client.
 *  Copyright (C) 2013 Timm Bäder
 *
 *  corebird is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  corebird is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with corebird.  If not, see <http://www.gnu.org/licenses/>.
 */

class FavoritesTimeline : IMessageReceiver, DefaultTimeline {
  protected override string function {
    get {
      return "1.1/favorites/list.json";
    }
  }

  public FavoritesTimeline (int id, Account account) {
    base (id);
    this.account = account;
    this.tweet_list.account = account;
  }

  private void stream_message_received (StreamMessageType type, Json.Node root) {
    if (type == StreamMessageType.EVENT_FAVORITE) {
      Json.Node tweet_obj = root.get_object ().get_member ("target_object");
      int64 tweet_id = tweet_obj.get_object ().get_int_member ("id");
      for (uint i = 0; i < this.tweet_list.model.get_n_items (); i ++) {
        Tweet t = (Tweet) this.tweet_list.model.get_item (i);

        if (t.id == tweet_id) {
          t.set_flag (TweetState.FAVORITED);
          // This tweet has been unfavorited and now favorited again,
          // so just mark it favorited and then return.
          return;
        }
      }

      Tweet tweet = new Tweet ();
      tweet.load_from_json (tweet_obj,
                            new GLib.DateTime.now_local (),
                            this.account);
      tweet.set_flag (TweetState.FAVORITED);
      var tle = new TweetListEntry (tweet, this.main_window, this.account);
      this.delta_updater.add (tle);
      this.tweet_list.add (tle);
    } else if (type == StreamMessageType.EVENT_UNFAVORITE) {
      int64 id = root.get_object ().get_object_member ("target_object").get_int_member ("id");
      toggle_favorite (id, false);
    }
  }


  public override void on_leave () {
    for (uint i = 0; i < tweet_list.model.get_n_items (); i ++) {
      var tweet = (Tweet) tweet_list.model.get_item (i);
      if (!tweet.is_flag_set (TweetState.FAVORITED)) {
        tweet_list.model.remove_tweet (tweet);
        i --;
      }
    }

    base.on_leave ();
  }


  public override void load_newest () {
    this.loading = true;
    this.load_newest_internal.begin (() => {
      this.loading = false;
    });
  }

  public override void load_older () {
    this.balance_next_upper_change (BOTTOM);
    this.loading = true;
    this.load_older_internal.begin (() => {
      this.loading = false;
    });
  }



  public override string? get_title () {
    return _("Favorites");
  }

  public override void create_tool_button (Gtk.RadioButton? group) {
    tool_button = new BadgeRadioToolButton(group, "starred-symbolic", _("Favorites"));
  }
}
