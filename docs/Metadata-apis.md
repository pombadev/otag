# [Napster](https://developer.napster.com/api)

## Examples

```bash

export NAPSTER_APIKEY=YTkxZTRhNzAtODdlNy00ZjMzLTg0MWItOTc0NmZmNjU4Yzk4

# get artist details
curl "http://api.napster.com/v2.2/artists/art.10434068?apikey=$NAPSTER_APIKEY"

# get album details
curl "https://api.napster.com/v2.2/artists/art.10434068/albums?apikey=$NAPSTER_APIKEY"

# get tracks
curl "https://api.napster.com/v2.2/albums/alb.338049241/tracks?apikey=$NAPSTER_APIKEY"

# search for an album
curl "http://api.napster.com/v2.2/search?apikey=$NAPSTER_APIKEY&query=No+Drum+And+Bass+In+The+Jazz+Room&type=album"

```

# [MusicBrainz](https://musicbrainz.org/doc/MusicBrainz_API)

## Examples

```bash

# search for an artist
curl "https://musicbrainz.org/ws/2/artist/?query=clever+girl" -H "Accept: application/json"


```

# [last.fm](https://www.last.fm/api)

## Examples

```bash

# search artist
curl "http://ws.audioscrobbler.com/2.0/?method=artist.search&api_key=$LASTFM_API_KEY&artist=clever+girl&format=json"

# get album info
curl "http://ws.audioscrobbler.com/2.0/?method=album.getinfo&api_key=$LASTFM_API_KEY&artist=Cher&album=Believe&format=json"

```