# README.md

# Rick and Morty wiki app

App work with rickandmortyapi.com API, where you can get info about:

1. All characters and complete information about them
2. All episodes with list of characters
3. Use search to find characters
4. Save favourites characters in your own
5. Offline

## Main screen

Collection view with all characters. Characters are loaded in batches of 20. With CoreData we can save info and media in own device to use app without internet. To go fully offline, needs to scroll all characters.

![Main Screen](https://user-images.githubusercontent.com/61178715/151514958-d2301bd2-29c5-449e-a49d-a7b92ed41a96.gif)

## Character info screen

Shows information received by API. From this screen you can get list of all episodes with this character.

![Character info screen](https://user-images.githubusercontent.com/61178715/151514989-4fbdff56-def1-4e55-a3e6-2a063784867c.gif)

## Episode list

Load data to device with first visit. Present small info about episode with episode’s name, short code and release data. After tap in anyone you can get list of all character in this episode and also can get character’s info.

![Episodes screen](https://user-images.githubusercontent.com/61178715/151515038-c212e0c2-9196-4835-9966-1c69c3397046.gif)

## Search screen

Search characters by name. If online, search work with API, if offline – search in stored data.

![Search screen](https://user-images.githubusercontent.com/61178715/151515257-3c4be778-76dc-459a-917e-a78eecff3363.gif)

## Favourites characters

Save the characters you have tagged by heart in his card. List of fav store on UserDefault, take info from API (online) or CoreData(offline)

![Favourite screen](https://user-images.githubusercontent.com/61178715/151515099-ce0ca39b-a431-4722-baf5-5afd6e03de58.gif)

# App work with

1. Screen with scroll by Collection and Table views
2. Navigation by Tab Bar, Navigation Controller and Segue
3. Reusable elements by Xib-files
4. Work with API by URLRequest
5. Store data on device by CoreData and UserDefaults
6. Load image by [Nuke](https://github.com/kean/Nuke)
