import os
import requests
from bs4 import BeautifulSoup
from time import sleep

import pandas as pd


def get_clubs_and_transfers(league_name, league_id, season_id, window):
    """Requests the Transfermarkt page for the input league season and scrapes the page HTML for transfer data.

    Args:
        league_name (str): Name of the league.
        league_id (str): League's unique Transfermarkt ID.
        season_id (str): First calendar year of the season, e.g. '2018' for 2018-19.
        window (str): 's' for summer or 'w' for winter transfer windows.
    Returns:
        A list of the clubs in the league, and two lists of tables (list of lists) for each club's transfer activity. 
    """
    headers = {'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/47.0.2526.106 Safari/537.36'}
    url = "https://www.transfermarkt.co.uk/{league_name}/transfers/wettbewerb/{league_id}/plus/?saison_id={season_id}&s_w={window}".format(league_name=league_name, league_id=league_id, season_id=season_id, window=window)
    try:
        print("Connecting...")
        response = requests.get(url, headers=headers)
        print("Connection successful, status code {}".format(response.status_code))
    except requests.exceptions.RequestException as e:
        print(e)
        exit()
    soup = BeautifulSoup(response.content, 'lxml')
    
    clubs = [tag.text for tag in soup.find_all('div', {'class': 'table-header'})][1:]
    
    tables = [tag.findChild() for tag in soup.find_all('div', {'class': 'responsive-table'})]
    table_in_list = tables[::2]
    table_out_list = tables[1::2]
    
    transfer_in_list = []
    transfer_out_list = []
    column_headers = {'season': season_id, 'window': window, 'league': league_name}
    for table_in, table_out in zip(table_in_list, table_out_list):
        transfer_in_list.append(get_transfer_info(table_in, movement='In', **column_headers))
        transfer_out_list.append(get_transfer_info(table_out, movement='Out', **column_headers))
    
    return clubs, transfer_in_list, transfer_out_list


def get_transfer_info(table, movement, season, window, league):
    """Helper function to parse an HTML table and extract all desired player information.

    Args:
        table (bs4.element.Tag): BeautifulSoup HTML table.
        movement (str): 'In' for arrival or 'Out' departure. 
        season (str): Season.
        window (str): 's' for summer or 'w' for winter.
        league (str): League name.
    Returns:
        The input table's information reformatted as a list of lists. 
    """
    transfer_info = []
    trs = table.find_all('tr')
    header_row = [header.get_text(strip=True) for header in trs[0].find_all('th')]
    if header_row:
        header_row[0] = 'Name'
        header_row.insert(0, 'Club')
        header_row[-2] = 'Club involved'
        header_row.insert(-1, 'Country involved')
        header_row += ['Movement', 'Season', 'Window', 'League']
        transfer_info.append(header_row)
    for tr in trs[1:]:
        row = []
        tds = tr.find_all('td')
        for td in tds:
            child = td.findChild()
            if child and child.get('class'):
                # Player name
                if child.get('class')[0] == 'di':
                    row.append(child.get_text(strip=True))
                # Player nationality
                elif child.get('class')[0] == 'flaggenrahmen':
                    row.append(child.get('alt'))
                # Club dealt to/from
                elif child.get('class')[0] == 'vereinprofil_tooltip':
                    row.append(child.findChild().get('alt'))
            else:
                row.append(td.get_text(strip=True))
        # Mark tables of no transfer activity with None for later cleaning
        if "No new arrivals" in row or "No departures" in row:
            transfer_info.append([None] * (len(header_row) - 1))
        else:
            row += [movement, season, window, league]
            transfer_info.append(row)
    
    return transfer_info


def formatted_transfers(clubs, transfers_in, transfers_out):
    """Prepends club names to their transfers.

    Args:
        clubs (list): List of clubs.
        transfers_in (list): List of lists.
        transfers_out (list): List of lists.
    Return:
        Updated transfer tables.
    """
    for i in range(len(clubs)):
        club_name = clubs[i]
        for row in transfers_in[i][1:]:
            row.insert(0, club_name)
        for row in transfers_out[i][1:]:
            row.insert(0, club_name)
    
    return transfers_in, transfers_out


def transfers_dataframe(tables_list):
    """Converts all transfer tables to dataframes then concatenates them into a single dataframe.

    Args:
        tables_list (list): List of transfer DataFrames.
    Returns:
        A DataFrame of all transfers.
    """
    return pd.concat([pd.DataFrame(table[1:], columns=table[0]) for table in tables_list])


def export_csv(df, season_id, league_name):
    """Writes an input DataFrame to a csv in its corresponding season's folder.

    Args:
        df (DataFrame): Transfer data to be exported.
        season_id (str): Folder in which to write the csv.
        league_name (str): File name for the csv.
    """
    file_name = '{}.csv'.format(league_name)
    current_dir = os.path.dirname(__file__)
    path_name = os.path.join(current_dir, '../data/{}'.format(season_id))
    if not os.path.exists(path_name):
        os.mkdir(path_name)
    
    export_name = os.path.join(path_name, file_name)
    df.to_csv(export_name, index=False, encoding='utf-8')


def scrape_season_transfers(league_name, league_id, season_id, window):
    """Web scrapes Transfermarkt for all transfer activity in a league's given window.

    Args:
        league_name (str): Name of the league.
        league_id (str): League's unique Transfermarkt ID.
        season_id (str): First calendar year of the season, e.g. '2018' for 2018-19.
        window (str): 's' for summer or 'w' for winter transfer windows.
    Returns:
        A DataFrame of all season transfer activity in the input league.
    """
    clubs, transfer_in_list, transfer_out_list = get_clubs_and_transfers(league_name, league_id, season_id, window)
    print("Got data for {} {} {} transfer window".format(season_id, league_name.upper(), window.upper()))
    transfers_in, transfers_out = formatted_transfers(clubs, transfer_in_list, transfer_out_list)
    print("Formatted transfers")
    df_in = transfers_dataframe(transfers_in)
    df_out = transfers_dataframe(transfers_out)
    print("Created dataframes")
    print("\n********************************\n")
    return pd.concat([df_in, df_out])


def transfers(league_name, league_id, start, stop):
    """Scrape a league's transfers over a range of seasons.

    Args:
        league_name (str): Name of the league.
        league_id (str): League's unique Transfermarkt ID.
        start (int): First calendar year of the first season to scrape, e.g. 1992 for the 1992/93 season.
        stop (int): Second calendar year of the last season, e.g. 2019 for the 2019/20 season.
    """
    try:
        for i in range(start, stop + 1):
            league_transfers = []
            season_id = str(i)
            for window in ['s', 'w']:
                league_transfers.append(scrape_season_transfers(league_name, league_id, season_id, window))
                sleep(3)
            df = pd.concat(league_transfers)
            df = df[~df['Name'].isna()]
            df.reset_index(drop=True, inplace=True)
            export_csv(df, season_id, league_name)
    except TypeError:
        print("Make sure league parameters are STRINGS and years are INTEGERS.")


def main():
    # England, Premier League
    print("Getting Premier League data...\n")
    transfers('premier-league', 'GB1', 1992, 2019)
    print("Done with the Premier League!")
    print("********************************\n")
    
    # Germany, Bundesliga
    print("Getting Bundesliga data...\n")
    transfers('1-bundesliga', 'L1', 1992, 2019)
    print("Done with the Bundesliga!")
    print("********************************\n")
    
    # Spain, La Liga
    print("Getting La Liga data...\n")
    transfers('laliga', 'ES1', 1992, 2019)
    print("********************************\n")
    
    # Italy, Serie A
    print("Getting Serie A data...\n")
    transfers('serie-a', 'IT1', 1992, 2019)
    print("Done with Serie A!")
    print("********************************\n")
    
    # France, Ligue 1
    print("Getting Ligue 1 data...\n")
    transfers('ligue-1', 'FR1', 1992, 2019)
    print("Done with Ligue 1!")
    print("********************************\n")
    
    print("\nDone!")


if __name__ == "__main__":
    main()
